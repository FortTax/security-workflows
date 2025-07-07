#!/usr/bin/env python3
"""
SOC2 Compliance API Endpoint
Simple Flask API to receive security scan results for SOC2 compliance tracking.

Requirements:
pip install flask psycopg2-binary python-dotenv

Environment Variables:
DATABASE_URL=postgresql://user:pass@host:port/dbname
API_SECRET_KEY=your_secret_key_here
PORT=5000
"""

import os
import json
import logging
from datetime import datetime
from typing import Dict, Any, Optional
try:
    from flask import Flask, request, jsonify
    import psycopg2
    from psycopg2.extras import RealDictCursor
    from dotenv import load_dotenv
except ImportError as e:
    print(f"Missing required packages: {e}")
    print("Please install: pip install flask psycopg2-binary python-dotenv")
    exit(1)

# Load environment variables
load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('API_SECRET_KEY', 'dev-secret-change-in-production')

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database connection
DATABASE_URL = os.getenv('DATABASE_URL')
if not DATABASE_URL:
    raise ValueError("DATABASE_URL environment variable is required")

def get_db_connection():
    """Get database connection"""
    try:
        conn = psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor)
        return conn
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        raise

def validate_api_key(request) -> bool:
    """Validate API key from request headers"""
    api_key = request.headers.get('Authorization', '').replace('Bearer ', '')
    expected_key = os.getenv('API_SECRET_KEY')

    if not api_key or api_key != expected_key:
        return False
    return True

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    try:
        conn = get_db_connection()
        conn.close()
        return jsonify({"status": "healthy", "timestamp": datetime.utcnow().isoformat()})
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 500

@app.route('/security-scans', methods=['POST'])
def receive_security_scan():
    """Receive security scan results for SOC2 compliance"""

    # Validate API key
    if not validate_api_key(request):
        logger.warning(f"Unauthorized access attempt from {request.remote_addr}")
        return jsonify({"error": "Unauthorized"}), 401

    try:
        # Parse JSON data
        data = request.get_json()
        if not data:
            return jsonify({"error": "No JSON data provided"}), 400

        # Extract data with defaults
        scan_metadata = data.get('scan_metadata', {})
        compliance_status = data.get('compliance_status', {})
        scan_results = data.get('scan_results', {})
        evidence_artifacts = data.get('evidence_artifacts', {})

        # Connect to database
        conn = get_db_connection()
        cur = conn.cursor()

        # Insert scan results
        insert_query = """
            INSERT INTO soc2_security_scans (
                timestamp, repository, application, branch, commit_sha, scan_type,
                overall_status, total_issues, severity_threshold,
                secrets_scanning, sast_scanning, dependency_scanning,
                container_scanning, dast_scanning,
                secrets_findings, sast_findings, dependency_vulnerabilities,
                web_security_grade, workflow_run_id, workflow_run_number,
                sarif_uploaded, artifacts_available, scan_metadata_json
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
            ) RETURNING id;
        """

        # Prepare data for insertion
        scan_time = datetime.fromisoformat(scan_metadata.get('timestamp', datetime.utcnow().isoformat()).replace('Z', '+00:00'))

        cur.execute(insert_query, (
            scan_time,
            scan_metadata.get('repository', ''),
            scan_metadata.get('application', ''),
            scan_metadata.get('branch', ''),
            scan_metadata.get('commit_sha', ''),
            scan_metadata.get('scan_type', ''),
            compliance_status.get('overall_status', 'UNKNOWN'),
            compliance_status.get('total_issues', 0),
            compliance_status.get('severity_threshold', ''),
            compliance_status.get('scan_coverage', {}).get('secrets_scanning', False),
            compliance_status.get('scan_coverage', {}).get('sast_scanning', False),
            compliance_status.get('scan_coverage', {}).get('dependency_scanning', False),
            compliance_status.get('scan_coverage', {}).get('container_scanning', False),
            compliance_status.get('scan_coverage', {}).get('dast_scanning', False),
            scan_results.get('secrets', {}).get('findings', 0),
            (scan_results.get('sast', {}).get('semgrep_findings', 0) +
             scan_results.get('sast', {}).get('eslint_findings', 0) +
             scan_results.get('sast', {}).get('bandit_findings', 0)),
            scan_results.get('dependencies', {}).get('vulnerabilities', 0),
            scan_results.get('web_security', {}).get('security_headers_grade', ''),
            scan_metadata.get('workflow_run_id'),
            scan_metadata.get('workflow_run_number'),
            evidence_artifacts.get('sarif_uploaded', False),
            evidence_artifacts.get('artifacts_available', True),
            json.dumps(data)  # Store full JSON for reference
        ))

        result = cur.fetchone()
        scan_id = result['id'] if result else None

        # Commit transaction
        conn.commit()

        logger.info(f"Security scan data stored successfully with ID: {scan_id}")

        # Check if this is a non-compliant scan and needs escalation
        if compliance_status.get('overall_status') == 'NON_COMPLIANT':
            logger.warning(f"NON-COMPLIANT scan detected for {scan_metadata.get('application', 'unknown')}")

            # Here you could add additional alerting logic:
            # - Send email to compliance officer
            # - Create ticket in ticketing system
            # - Send to Slack/Teams
            # - Update external SOC2 platform

        return jsonify({
            "status": "success",
            "scan_id": scan_id,
            "message": "Security scan data received and stored",
            "compliance_status": compliance_status.get('overall_status', 'UNKNOWN')
        }), 201

    except psycopg2.Error as e:
        logger.error(f"Database error: {e}")
        if 'conn' in locals():
            conn.rollback()
        return jsonify({"error": "Database error occurred"}), 500

    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return jsonify({"error": "Internal server error"}), 500

    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals():
            conn.close()

@app.route('/compliance-report', methods=['GET'])
def get_compliance_report():
    """Get SOC2 compliance summary report"""

    # Validate API key
    if not validate_api_key(request):
        return jsonify({"error": "Unauthorized"}), 401

    try:
        # Get query parameters
        days = request.args.get('days', 30, type=int)
        application = request.args.get('application')

        conn = get_db_connection()
        cur = conn.cursor()

        # Base query
        base_where = "WHERE timestamp >= NOW() - INTERVAL %s"
        params = [f"{days} days"]

        if application:
            base_where += " AND application = %s"
            params.append(application)

        # Get overall statistics
        stats_query = f"""
            SELECT
                COUNT(*) as total_scans,
                COUNT(*) FILTER (WHERE overall_status = 'COMPLIANT') as compliant_scans,
                COUNT(*) FILTER (WHERE overall_status = 'NON_COMPLIANT') as non_compliant_scans,
                AVG(total_issues) as avg_issues_per_scan,
                MAX(total_issues) as max_issues_in_scan
            FROM soc2_security_scans
            {base_where}
        """

        cur.execute(stats_query, params)
        stats_result = cur.fetchone()

        # Get application breakdown
        app_query = f"""
            SELECT
                application,
                COUNT(*) as scans,
                COUNT(*) FILTER (WHERE overall_status = 'COMPLIANT') as compliant,
                AVG(total_issues) as avg_issues
            FROM soc2_security_scans
            {base_where}
            GROUP BY application
            ORDER BY scans DESC
        """

        cur.execute(app_query, params)
        applications = cur.fetchall()

        # Get recent non-compliant scans
        recent_issues_query = f"""
            SELECT
                application, repository, timestamp, total_issues,
                workflow_run_id, overall_status
            FROM soc2_security_scans
            {base_where} AND overall_status = 'NON_COMPLIANT'
            ORDER BY timestamp DESC
            LIMIT 10
        """

        cur.execute(recent_issues_query, params)
        recent_issues = cur.fetchall()

        # Calculate compliance percentage
        compliance_percentage = 0
        if stats_result and stats_result['total_scans'] > 0:
            compliance_percentage = (stats_result['compliant_scans'] / stats_result['total_scans']) * 100

        report = {
            "report_generated": datetime.utcnow().isoformat(),
            "period_days": days,
            "filter_application": application,
            "summary": {
                "total_scans": stats_result['total_scans'] if stats_result else 0,
                "compliant_scans": stats_result['compliant_scans'] if stats_result else 0,
                "non_compliant_scans": stats_result['non_compliant_scans'] if stats_result else 0,
                "compliance_percentage": round(compliance_percentage, 2),
                "avg_issues_per_scan": round(float(stats_result['avg_issues_per_scan'] or 0), 2) if stats_result else 0,
                "max_issues_in_scan": stats_result['max_issues_in_scan'] if stats_result else 0
            },
            "applications": [dict(app) for app in applications],
            "recent_non_compliant_scans": [dict(issue) for issue in recent_issues]
        }

        return jsonify(report)

    except Exception as e:
        logger.error(f"Error generating compliance report: {e}")
        return jsonify({"error": "Failed to generate report"}), 500

    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals():
            conn.close()

@app.route('/compliance-status/<application>', methods=['GET'])
def get_application_status(application):
    """Get current compliance status for a specific application"""

    # Validate API key
    if not validate_api_key(request):
        return jsonify({"error": "Unauthorized"}), 401

    try:
        conn = get_db_connection()
        cur = conn.cursor()

        # Get latest scan for application
        query = """
            SELECT * FROM soc2_security_scans
            WHERE application = %s
            ORDER BY timestamp DESC
            LIMIT 1
        """

        cur.execute(query, [application])
        latest_scan = cur.fetchone()

        if not latest_scan:
            return jsonify({"error": "Application not found"}), 404

        return jsonify({
            "application": application,
            "current_status": latest_scan['overall_status'],
            "last_scan": latest_scan['timestamp'].isoformat(),
            "total_issues": latest_scan['total_issues'],
            "scan_coverage": {
                "secrets_scanning": latest_scan['secrets_scanning'],
                "sast_scanning": latest_scan['sast_scanning'],
                "dependency_scanning": latest_scan['dependency_scanning'],
                "container_scanning": latest_scan['container_scanning'],
                "dast_scanning": latest_scan['dast_scanning']
            }
        })

    except Exception as e:
        logger.error(f"Error getting application status: {e}")
        return jsonify({"error": "Failed to get status"}), 500

    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals():
            conn.close()

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('FLASK_ENV') == 'development'

    logger.info(f"Starting SOC2 Compliance API on port {port}")
    app.run(host='0.0.0.0', port=port, debug=debug)
