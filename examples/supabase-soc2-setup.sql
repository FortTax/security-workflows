-- Supabase SOC2 Security Scanning Database Setup
-- Execute this in your Supabase SQL editor

-- Enable Row Level Security for SOC2 compliance
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

-- Create security_scans table
CREATE TABLE security_scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    repository VARCHAR(255) NOT NULL,
    application VARCHAR(255) NOT NULL,
    branch VARCHAR(100),
    commit_sha VARCHAR(40),
    scan_type VARCHAR(50),
    overall_status VARCHAR(20) CHECK (overall_status IN ('COMPLIANT', 'NON_COMPLIANT')),
    total_issues INTEGER DEFAULT 0,
    severity_threshold VARCHAR(20),

    -- Scan Coverage
    secrets_scanning BOOLEAN DEFAULT FALSE,
    sast_scanning BOOLEAN DEFAULT FALSE,
    dependency_scanning BOOLEAN DEFAULT FALSE,
    container_scanning BOOLEAN DEFAULT FALSE,
    dast_scanning BOOLEAN DEFAULT FALSE,

    -- Detailed Results
    scan_results JSONB DEFAULT '{}',
    evidence_artifacts JSONB DEFAULT '{}',

    -- Workflow Info
    workflow_run_id BIGINT,
    workflow_run_number INTEGER,

    -- SOC2 Compliance
    compliance_officer_reviewed BOOLEAN DEFAULT FALSE,
    remediation_due_date TIMESTAMP WITH TIME ZONE,
    remediation_status VARCHAR(20) DEFAULT 'PENDING',
    audit_notes TEXT,

    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_security_scans_timestamp ON security_scans(timestamp);
CREATE INDEX idx_security_scans_status ON security_scans(overall_status);
CREATE INDEX idx_security_scans_app ON security_scans(application);
CREATE INDEX idx_security_scans_repo ON security_scans(repository);

-- Create compliance_summary view for dashboards
CREATE OR REPLACE VIEW compliance_summary AS
SELECT
    application,
    COUNT(*) as total_scans,
    COUNT(*) FILTER (WHERE overall_status = 'COMPLIANT') as compliant_scans,
    COUNT(*) FILTER (WHERE overall_status = 'NON_COMPLIANT') as non_compliant_scans,
    ROUND(
        (COUNT(*) FILTER (WHERE overall_status = 'COMPLIANT') * 100.0) / COUNT(*),
        2
    ) as compliance_percentage,
    AVG(total_issues) as avg_issues,
    MAX(timestamp) as last_scan,
    MIN(timestamp) as first_scan
FROM security_scans
WHERE timestamp >= NOW() - INTERVAL '30 days'
GROUP BY application
ORDER BY compliance_percentage DESC;

-- Create recent_issues view for monitoring
CREATE OR REPLACE VIEW recent_issues AS
SELECT
    application,
    repository,
    timestamp,
    total_issues,
    overall_status,
    scan_results,
    workflow_run_id,
    remediation_status
FROM security_scans
WHERE overall_status = 'NON_COMPLIANT'
    AND timestamp >= NOW() - INTERVAL '7 days'
ORDER BY timestamp DESC;

-- Row Level Security Policies (SOC2 Compliance)
ALTER TABLE security_scans ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see scans for their organization
CREATE POLICY "Users can view security scans for their org" ON security_scans
    FOR SELECT USING (
        auth.jwt() ->> 'org_id' = (
            SELECT org_id FROM user_organizations
            WHERE user_id = auth.uid()
        )
    );

-- Policy: Only compliance officers can update audit notes
CREATE POLICY "Only compliance officers can update audit notes" ON security_scans
    FOR UPDATE USING (
        auth.jwt() ->> 'role' = 'compliance_officer'
    );

-- Policy: API access for security scan ingestion
CREATE POLICY "API can insert security scans" ON security_scans
    FOR INSERT WITH CHECK (
        auth.jwt() ->> 'role' = 'security_scanner'
    );

-- Create API key for GitHub Actions
-- Generate this in Supabase dashboard under API settings
-- Then add to GitHub secrets as: SUPABASE_API_KEY=your_service_role_key

-- Create function to handle scan ingestion
CREATE OR REPLACE FUNCTION handle_security_scan_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Update compliance dashboard in real-time
    PERFORM pg_notify('security_scan_update',
        json_build_object(
            'application', NEW.application,
            'status', NEW.overall_status,
            'timestamp', NEW.timestamp
        )::text
    );

    -- Auto-create remediation tasks for non-compliant scans
    IF NEW.overall_status = 'NON_COMPLIANT' THEN
        INSERT INTO remediation_tasks (
            security_scan_id,
            application,
            priority,
            due_date,
            status,
            description
        ) VALUES (
            NEW.id,
            NEW.application,
            CASE
                WHEN NEW.total_issues > 10 THEN 'HIGH'
                WHEN NEW.total_issues > 5 THEN 'MEDIUM'
                ELSE 'LOW'
            END,
            NOW() + INTERVAL '7 days',
            'OPEN',
            'Remediate security issues found in scan #' || NEW.workflow_run_number
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for scan processing
CREATE TRIGGER security_scan_insert_trigger
    AFTER INSERT ON security_scans
    FOR EACH ROW EXECUTE FUNCTION handle_security_scan_insert();

-- Create remediation_tasks table
CREATE TABLE remediation_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    security_scan_id UUID REFERENCES security_scans(id),
    application VARCHAR(255) NOT NULL,
    priority VARCHAR(10) CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    due_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'IN_PROGRESS', 'COMPLETED', 'DEFERRED')),
    description TEXT,
    assigned_to UUID REFERENCES auth.users(id),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create dashboard metrics function
CREATE OR REPLACE FUNCTION get_soc2_dashboard_metrics(days_back INTEGER DEFAULT 30)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'summary', (
            SELECT json_build_object(
                'total_scans', COUNT(*),
                'compliant_scans', COUNT(*) FILTER (WHERE overall_status = 'COMPLIANT'),
                'non_compliant_scans', COUNT(*) FILTER (WHERE overall_status = 'NON_COMPLIANT'),
                'compliance_percentage', ROUND(
                    (COUNT(*) FILTER (WHERE overall_status = 'COMPLIANT') * 100.0) / COUNT(*),
                    2
                ),
                'avg_issues', ROUND(AVG(total_issues), 2),
                'period_days', days_back
            )
            FROM security_scans
            WHERE timestamp >= NOW() - (days_back || ' days')::INTERVAL
        ),
        'by_application', (
            SELECT json_agg(
                json_build_object(
                    'application', application,
                    'compliance_percentage', compliance_percentage,
                    'total_scans', total_scans,
                    'last_scan', last_scan
                )
            )
            FROM compliance_summary
        ),
        'recent_issues', (
            SELECT json_agg(
                json_build_object(
                    'application', application,
                    'repository', repository,
                    'timestamp', timestamp,
                    'total_issues', total_issues,
                    'remediation_status', remediation_status
                )
            )
            FROM recent_issues
            LIMIT 10
        )
    ) INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON compliance_summary TO anon, authenticated;
GRANT SELECT ON recent_issues TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_soc2_dashboard_metrics TO anon, authenticated;

-- Create API endpoint helper
CREATE OR REPLACE FUNCTION create_security_scan(scan_data JSON)
RETURNS JSON AS $$
DECLARE
    scan_id UUID;
    result JSON;
BEGIN
    INSERT INTO security_scans (
        timestamp,
        repository,
        application,
        branch,
        commit_sha,
        scan_type,
        overall_status,
        total_issues,
        severity_threshold,
        secrets_scanning,
        sast_scanning,
        dependency_scanning,
        container_scanning,
        dast_scanning,
        scan_results,
        evidence_artifacts,
        workflow_run_id,
        workflow_run_number
    ) VALUES (
        (scan_data->'scan_metadata'->>'timestamp')::TIMESTAMP WITH TIME ZONE,
        scan_data->'scan_metadata'->>'repository',
        scan_data->'scan_metadata'->>'application',
        scan_data->'scan_metadata'->>'branch',
        scan_data->'scan_metadata'->>'commit_sha',
        scan_data->'scan_metadata'->>'scan_type',
        scan_data->'compliance_status'->>'overall_status',
        (scan_data->'compliance_status'->>'total_issues')::INTEGER,
        scan_data->'compliance_status'->>'severity_threshold',
        (scan_data->'compliance_status'->'scan_coverage'->>'secrets_scanning')::BOOLEAN,
        (scan_data->'compliance_status'->'scan_coverage'->>'sast_scanning')::BOOLEAN,
        (scan_data->'compliance_status'->'scan_coverage'->>'dependency_scanning')::BOOLEAN,
        (scan_data->'compliance_status'->'scan_coverage'->>'container_scanning')::BOOLEAN,
        (scan_data->'compliance_status'->'scan_coverage'->>'dast_scanning')::BOOLEAN,
        scan_data->'scan_results',
        scan_data->'evidence_artifacts',
        (scan_data->'scan_metadata'->>'workflow_run_id')::BIGINT,
        (scan_data->'scan_metadata'->>'workflow_run_number')::INTEGER
    ) RETURNING id INTO scan_id;

    SELECT json_build_object(
        'success', true,
        'scan_id', scan_id,
        'message', 'Security scan data stored successfully'
    ) INTO result;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Sample data for testing (remove in production)
INSERT INTO security_scans (
    repository, application, overall_status, total_issues,
    scan_results, evidence_artifacts
) VALUES (
    'pfic-wizard', 'core-pfic', 'COMPLIANT', 0,
    '{"secrets": {"findings": 0}, "sast": {"findings": 0}}',
    '{"sarif_uploaded": true, "workflow_run_id": 12345}'
);

-- Create dashboard user (for Grafana/similar)
-- INSERT INTO auth.users (email, role) VALUES ('dashboard@yourcompany.com', 'dashboard_viewer');

COMMENT ON TABLE security_scans IS 'SOC2 security scan results for compliance monitoring';
COMMENT ON FUNCTION get_soc2_dashboard_metrics IS 'Get comprehensive SOC2 dashboard metrics';
COMMENT ON VIEW compliance_summary IS 'Application-level compliance summary for dashboards';
