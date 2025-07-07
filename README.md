# FortTax Security Workflows

🛡️ **Centralized Security Scanning Framework for GitHub Actions**

This repository provides reusable security workflows that can be used across
multiple repositories to implement consistent, comprehensive security scanning.

## 🚀 Quick Start

Add this to your repository's `.github/workflows/centralized-security-scan.yml`:

```yaml
name: Centralized Security Scan

on:
  pull_request:
    branches: [main, staging]
  workflow_run:
    workflows: ["Your Deploy Workflow"]
    types: [completed]
    branches: [main, staging]
  schedule:
    - cron: "0 10 * * 1" # Weekly scan
  workflow_dispatch:

jobs:
  security-scan:
    uses: FortTax/security-workflows/.github/workflows/reusable-security-scan.yml@main
    with:
      app_name: "Your App Name"
      scan_type: "frontend" # or "backend", "all"
      target_url: "https://your-app.com"
      include_financial_compliance: true
    secrets:
      SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      FOSSA_API_KEY: ${{ secrets.FOSSA_API_KEY }}
      SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
```

## 🏢 Deployed Applications

### Currently Configured Applications

| Application             | Framework    | URL                                    | Scan Schedule |
| ----------------------- | ------------ | -------------------------------------- | ------------- |
| **Portal Tax Analyzer** | VITE + React | https://portal-tax-analyzer.vercel.app | Mon 10:00 UTC |
| **CFC Wizard v2**       | VITE + React | https://cfc-wizard-v2.vercel.app       | Mon 11:00 UTC |
| **PFIC Wizard**         | NextJS       | https://pfic-wizard.vercel.app         | Mon 12:00 UTC |

### Implementation Status

✅ **Portal Tax Analyzer**

- Centralized security workflow: `centralized-security-scan.yml`
- Framework auto-detection: VITE
- Financial compliance: Enabled
- DAST scanning: Enabled with target URL

✅ **CFC Wizard v2**

- Centralized security workflow: `centralized-security-scan.yml`
- Framework auto-detection: VITE
- Financial compliance: Enabled
- DAST scanning: Enabled with target URL

✅ **PFIC Wizard**

- Centralized security workflow: `centralized-security-scan.yml`
- Framework auto-detection: NextJS
- Financial compliance: Enabled
- DAST scanning: Enabled with target URL

## 🔧 Available Workflows

| Workflow                     | Purpose                    | Best For         |
| ---------------------------- | -------------------------- | ---------------- |
| `reusable-security-scan.yml` | Complete security scanning | All applications |

## 📊 Security Tools Included

| Tool                | Purpose                                     | Always Runs                   | Requires Secret |
| ------------------- | ------------------------------------------- | ----------------------------- | --------------- |
| **GitLeaks**        | Secrets detection                           | ✅                            | No              |
| **ESLint Security** | Free SAST for JavaScript/TypeScript         | ✅                            | No              |
| **Bandit**          | Free SAST for Python files                  | ✅ (if Python found)          | No              |
| **Semgrep**         | SAST scanning (free rules only)            | ✅                            | No              |
| **npm audit**       | Basic dependency scanning                   | ✅                            | No              |
| **Snyk**            | Enhanced dependency vulnerability scanning  | ✅ **ORGANIZATION ACTIVE**    | ✅              |
| **Trivy**           | Container/filesystem security               | ✅                            | No              |
| **OWASP ZAP**       | Dynamic Application Security Testing (DAST) | Only if `target_url` provided | No              |
| **SecurityHeaders.com** | HTTP security headers analysis           | Only if `target_url` provided | No              |
| **Checkov**         | Infrastructure as Code (IaC) security       | ✅                            | No              |
| **FOSSA**           | License compliance scanning                 | ✅ **ORGANIZATION ACTIVE**    | ✅              |
| **Custom**          | Financial services compliance checks        | ✅                            | No              |
| **Custom**          | Insecure token storage detection            | ✅                            | No              |

## ⚙️ Configuration Options

### Required Inputs

- `app_name` - Name of your application

### Optional Inputs

- `target_url` - URL for DAST scanning (web applications)
- `scan_type` - Types of scans to run:
  - `frontend` - Frontend-optimized (SAST, secrets, dependencies, container,
    DAST)
  - `backend` - Backend-optimized (SAST, secrets, dependencies, container, IaC)
  - `all` - Run all security scans (default)
  - `sast` - Static code analysis only
  - `secrets` - Secrets detection only
  - `dependencies` - Dependency scanning only
  - `container` - Container security only
  - `iac` - Infrastructure as Code security only
  - `dast` - Dynamic application testing only
  - `license` - License compliance only
  - `financial` - Financial compliance checks only
- `app_framework` - Application framework (`vite`, `nextjs`, `react`, `node`,
  `auto-detect`)
- `node_version` - Node.js version to use (default: `18`)
- `include_financial_compliance` - Enable fintech-specific compliance checks
  (default: `true`)
- `severity_threshold` - Minimum severity to report (`low`, `medium`, `high`,
  `critical`)
- `notification_email` - Email for security alerts

### Organization Secrets (Current Configuration)

- ✅ `SNYK_TOKEN` - **ACTIVE** - Enhanced dependency vulnerability scanning
- ✅ `FOSSA_API_KEY` - **ACTIVE** - Professional license compliance analysis
- ❌ `SEMGREP_APP_TOKEN` - **NOT USED** - Using free Semgrep rules instead

## 🏦 Financial Services Compliance

When `include_financial_compliance: true` (default), additional checks are
performed for:

- **PCI DSS** - Payment card industry standards
- **Tax Software Compliance** - IRS, CFC, PFIC, tax return processing
- **Financial Data Handling** - SSN, TIN, EIN, routing numbers, account numbers
- **Security Implementation** - Encryption, JWT, secure authentication
- **Token Storage Security** - Detection of insecure localStorage/sessionStorage
  usage

### Tax Software Specific Checks

The framework includes specialized checks for tax software applications:

- **IRS Form Processing** - Detection of 1040, 8865, and other tax forms
- **CFC Analysis** - Controlled Foreign Corporation compliance
- **PFIC Reporting** - Passive Foreign Investment Company compliance
- **Financial Data Security** - Enhanced protection for sensitive tax data

## 🔄 Scan Triggers

### Automatic Triggers

1. **Pull Requests** - Quick security review before merge
2. **Post-Deployment** - Comprehensive scan after successful deployment
3. **Weekly Schedule** - Full security audit (Mondays, staggered times)

### Manual Triggers

- **workflow_dispatch** - Manual execution with custom parameters
- Supports custom URL and scan type selection

## ⚠️ Important: Avoiding Duplicate Security Scans

**CRITICAL:** Each repository should have only **ONE** security workflow to
avoid duplicate scans and resource waste.

### Migration from Existing Workflows

When implementing the centralized security scan, disable or remove these
existing workflows:

#### Portal Tax Analyzer

- ❌ `post-deployment-security.yml` (can be disabled)
- ❌ `simple-security-scan.yml` (can be disabled)
- ❌ `debug-security-scan.yml` (can be disabled)

#### CFC Wizard v2

- ❌ `standalone-security-scan.yml` (can be disabled)
- ❌ `post-deployment-security.yml` (can be disabled)

#### PFIC Wizard

- ❌ `security-scan.yml` (can be disabled)
- ❌ `manual-security-scan.yml` (can be disabled)
- ❌ `post-deployment-security.yml` (can be disabled)

### Recommended Implementation Steps

1. **Deploy centralized workflow** - Add `centralized-security-scan.yml`
2. **Test manual trigger** - Verify the new workflow works
3. **Disable old workflows** - Comment out or delete existing security workflows
4. **Update secrets** - Ensure all required secrets are configured
5. **Monitor results** - Check security scan outputs and artifacts

## 🔗 Implementation Examples

### Frontend Application (VITE/React)

```yaml
name: Centralized Security Scan

on:
  pull_request:
    branches: [main, staging]
  workflow_run:
    workflows: ["Deploy"]
    types: [completed]
    branches: [main, staging]
  schedule:
    - cron: "0 10 * * 1"
  workflow_dispatch:

jobs:
  check-deployment:
    runs-on: ubuntu-latest
    outputs:
      should_scan: ${{ steps.check.outputs.should_scan }}
      app_url: ${{ steps.check.outputs.app_url }}
      scan_type: ${{ steps.check.outputs.scan_type }}
    steps:
      - name: Determine scan parameters
        id: check
        run: |
          # Logic to determine when and what to scan
          echo "should_scan=true" >> $GITHUB_OUTPUT
          echo "app_url=https://your-app.com" >> $GITHUB_OUTPUT
          echo "scan_type=frontend" >> $GITHUB_OUTPUT

  security-scan:
    needs: check-deployment
    if: needs.check-deployment.outputs.should_scan == 'true'
    uses: FortTax/security-workflows/.github/workflows/reusable-security-scan.yml@main
    with:
      app_name: "Your Frontend App"
      target_url: ${{ needs.check-deployment.outputs.app_url }}
      scan_type: ${{ needs.check-deployment.outputs.scan_type }}
      include_financial_compliance: true
      severity_threshold: "medium"
      notification_email: "security@yourcompany.com"
    secrets:
      SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      FOSSA_API_KEY: ${{ secrets.FOSSA_API_KEY }}
      # SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}  # Not currently used
```

### Backend Service

```yaml
jobs:
  security-scan:
    uses: FortTax/security-workflows/.github/workflows/reusable-security-scan.yml@main
    with:
      app_name: "Your Backend Service"
      scan_type: "backend" # No DAST scanning
      include_financial_compliance: true
      severity_threshold: "high" # Stricter for backend
    secrets:
      SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      FOSSA_API_KEY: ${{ secrets.FOSSA_API_KEY }}
      # SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}  # Not currently used
```

## 📈 Security Metrics and Reporting

### Automated Reporting

- **GitHub Security Tab** - SARIF results uploaded automatically
- **Workflow Artifacts** - Detailed scan results for download
- **Job Summaries** - Executive summary in workflow output
- **Email Notifications** - Alerts for critical security issues

### Key Metrics Tracked

- **Secrets Detection** - Count of potential secrets found
- **SAST Findings** - Security vulnerabilities in code
- **Dependency Vulnerabilities** - Known CVEs in dependencies
- **License Compliance** - License compatibility issues
- **Financial Compliance** - Tax/financial regulation adherence

## 🛠️ Troubleshooting

### Common Issues

1. **Workflow not triggering**
   - Check `workflow_run` references correct deployment workflow name
   - Verify permissions are set correctly

2. **Scan failures**
   - Review artifact downloads for detailed error logs
   - Check if secrets are properly configured

3. **False positives**
   - Configure `.gitleaks.toml` for secrets scanning
   - Add Semgrep rule exclusions as needed

### Debug Mode

Enable debug mode by triggering manual workflow dispatch with verbose logging.

## 🔐 Security Best Practices

1. **Secrets Management** - Never commit API tokens to repositories
2. **Regular Updates** - Keep security tools and rulesets updated
3. **Immediate Response** - Address critical security findings quickly
4. **Documentation** - Maintain security scan documentation
5. **Training** - Ensure team understands security workflow outputs

---

**Framework Maintained By:** FortTax Security Team **Last Updated:** {{
current_date }} **Version:** 2.0.0 - Enhanced Multi-Application Support
