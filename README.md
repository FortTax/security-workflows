# FortTax Security Workflows

🛡️ **Centralized Security Scanning Framework for GitHub Actions**

This repository provides reusable security workflows that can be used across
multiple repositories to implement consistent, comprehensive security scanning.

## 🚀 Quick Start

Add this to your repository's `.github/workflows/security-scan.yml`:

```yaml
name: Security Scan

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  security-scan:
    uses: FortTax/security-workflows/.github/workflows/reusable-security-scan.yml@main
    with:
      app_name: "Your App Name"
      scan_type: "all"
      include_financial_compliance: false
    secrets:
      SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      FOSSA_API_KEY: ${{ secrets.FOSSA_API_KEY }}
      SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
```

## 🔧 Available Workflows

| Workflow                     | Purpose                    | Best For         |
| ---------------------------- | -------------------------- | ---------------- |
| `reusable-security-scan.yml` | Complete security scanning | All applications |

## 📊 Security Tools Included

| Tool          | Purpose                                     | Always Runs                   | Requires Secret |
| ------------- | ------------------------------------------- | ----------------------------- | --------------- |
| **Semgrep**   | Static Application Security Testing (SAST)  | ✅                            | Optional        |
| **GitLeaks**  | Secrets detection                           | ✅                            | No              |
| **OWASP ZAP** | Dynamic Application Security Testing (DAST) | Only if `target_url` provided | No              |
| **Trivy**     | Container/filesystem security               | ✅                            | No              |
| **Checkov**   | Infrastructure as Code (IaC) security       | ✅                            | No              |
| **Snyk**      | Dependency vulnerability scanning           | Only if token provided        | ✅              |
| **FOSSA**     | License compliance scanning                 | Only if token provided        | ✅              |
| **Custom**    | Financial services compliance checks        | Only if enabled               | No              |

## ⚙️ Configuration Options

### Required Inputs

- `app_name` - Name of your application

### Optional Inputs

- `target_url` - URL for DAST scanning (web applications)
- `scan_type` - Types of scans to run:
  - `all` - Run all security scans (default)
  - `backend` - Backend-optimized (SAST, secrets, dependencies, container, IaC)
  - `sast` - Static code analysis only
  - `secrets` - Secrets detection only
  - `dependencies` - Dependency scanning only
  - `container` - Container security only
  - `iac` - Infrastructure as Code security only
  - `dast` - Dynamic application testing only
  - `license` - License compliance only
  - `financial` - Financial compliance checks only
- `include_financial_compliance` - Enable fintech-specific compliance checks
- `severity_threshold` - Minimum severity to report (`low`, `medium`, `high`,
  `critical`)
- `notification_email` - Email for security alerts

### Optional Secrets

- `SNYK_TOKEN` - For enhanced dependency scanning
- `FOSSA_API_KEY` - For license compliance scanning
- `SEMGREP_APP_TOKEN` - For enhanced SAST scanning

## 🏦 Financial Services Compliance

When `include_financial_compliance: true`, additional checks are performed for:

- **PCI DSS** - Payment card industry standards
- **FFIEC CAT** - Financial institution cybersecurity assessment
- **SOC 2** - Service organization controls
- **GDPR** - Data protection compliance

## ⚠️ Important: Avoiding Duplicate Security Scans

**CRITICAL:** Ensure you only have **ONE** security workflow per repository to
avoid duplicate scans and resource waste.

### Common Issues to Avoid

❌ **Don't do this** - Multiple security workflows:

```yaml
# BAD: Multiple files triggering on same events
# security-scan.yml
on:
  push:
    branches: [main]

# security-scan-internal.yml
on:
  push:
    branches: [main]
```

✅ **Do this instead** - Single workflow with proper timing:

```yaml
# GOOD: One workflow after deployment
on:
  pull_request:
    branches: [main]
  workflow_run:
    workflows: ["Test and Deploy"]
    types: [completed]
    branches: [main]
```

### Recommended Workflow Timing

1. **For Pull Requests**: Run security scans for code review
2. **For Deployments**: Run security scans AFTER successful deployment
3. **For Scheduled**: Run weekly comprehensive scans
4. **For Dormant Repos**: Run monthly scans if no recent activity

```yaml
name: Security Scan

on:
  # Code review security check
  pull_request:
    branches: [main]

  # Post-deployment security scan
  workflow_run:
    workflows: ["Test and Deploy"]
    types: [completed]
    branches: [main]

  # Scheduled scans
  schedule:
    # Weekly comprehensive scan (Mondays at 10 AM UTC)
    - cron: "0 10 * * 1"
    # Monthly dormant repository scan (1st of month at 9 AM UTC)
    - cron: "0 9 1 * *"

  # Manual trigger
  workflow_dispatch:

jobs:
  # Check if repository needs scanning (for scheduled events)
  check-scan-needed:
    if: github.event_name == 'schedule'
    runs-on: ubuntu-latest
    outputs:
      should_scan: ${{ steps.check.outputs.should_scan }}
      scan_reason: ${{ steps.check.outputs.scan_reason }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check if scan is needed
        id: check
        run: |
          # For monthly schedule (1st of month), check if repo has been dormant
          if [[ "${{ github.event.schedule }}" == "0 9 1 * *" ]]; then
            echo "🗓️ Monthly dormant repository check..."

            # Check last commit date
            LAST_COMMIT_DATE=$(git log -1 --format=%ct)
            CURRENT_DATE=$(date +%s)
            DAYS_SINCE_LAST_COMMIT=$(( (CURRENT_DATE - LAST_COMMIT_DATE) / 86400 ))

            echo "Last commit was $DAYS_SINCE_LAST_COMMIT days ago"

            if [ $DAYS_SINCE_LAST_COMMIT -gt 30 ]; then
              echo "should_scan=true" >> $GITHUB_OUTPUT
              echo "scan_reason=Dormant repository (${DAYS_SINCE_LAST_COMMIT} days since last commit)" >> $GITHUB_OUTPUT
              echo "✅ Repository dormant for $DAYS_SINCE_LAST_COMMIT days - security scan needed"
            else
              echo "should_scan=false" >> $GITHUB_OUTPUT
              echo "scan_reason=Recent activity (${DAYS_SINCE_LAST_COMMIT} days since last commit)" >> $GITHUB_OUTPUT
              echo "⏭️ Repository active (last commit $DAYS_SINCE_LAST_COMMIT days ago) - skipping scan"
            fi
          else
            # Weekly scan always runs
            echo "should_scan=true" >> $GITHUB_OUTPUT
            echo "scan_reason=Weekly comprehensive scan" >> $GITHUB_OUTPUT
            echo "✅ Weekly comprehensive scan scheduled"
          fi

  security-scan:
    needs: [check-scan-needed]
    # Only run if deployment succeeded, manual trigger, PR, or scheduled scan is needed
    if: |
      github.event_name == 'workflow_dispatch' ||
      github.event_name == 'pull_request' ||
      (github.event_name == 'workflow_run' && github.event.workflow_run.conclusion == 'success') ||
      (github.event_name == 'schedule' && needs.check-scan-needed.outputs.should_scan == 'true')

    uses: FortTax/security-workflows/.github/workflows/reusable-security-scan.yml@main
    with:
      app_name: "Your App"
      scan_type: "all"
```

## 📋 Usage Examples

### Web Application

```yaml
jobs:
  security-scan:
    uses: FortTax/security-workflows/.github/workflows/reusable-security-scan.yml@main
    with:
      app_name: "Customer Portal"
      target_url: "https://portal.company.com"
      scan_type: "all"
      severity_threshold: "medium"
```

### Backend API

```yaml
jobs:
  security-scan:
    uses: FortTax/security-workflows/.github/workflows/reusable-security-scan.yml@main
    with:
      app_name: "API Backend"
      scan_type: "backend" # No DAST for APIs
      severity_threshold: "high"
```

### Financial/Fintech Application

```yaml
jobs:
  security-scan:
    uses: FortTax/security-workflows/.github/workflows/reusable-security-scan.yml@main
    with:
      app_name: "Payment System"
      target_url: "https://payments.company.com"
      scan_type: "all"
      include_financial_compliance: true
      severity_threshold: "high"
      notification_email: "security@company.com"
    secrets:
      SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      FOSSA_API_KEY: ${{ secrets.FOSSA_API_KEY }}
      SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}
```

## 🔍 Results & Evidence

### Where to Find Results

1. **GitHub Security Tab** - `/security` - Automated security alerts
2. **GitHub Actions** - `/actions` - Detailed workflow logs
3. **Issues** - Automatic creation for findings (with `forttax-security-scan`
   label)
4. **SARIF Files** - Uploaded to GitHub for integrated security overview

### SOC 2 Compliance Evidence

The framework automatically provides evidence for:

- **Continuous monitoring** - Every deployment scanned
- **Threat detection** - Multiple security tools covering various attack vectors
- **Incident response** - Automated alerting and issue creation
- **Access controls** - Code and infrastructure scanning
- **Data protection** - Secrets and vulnerability detection

## 🔄 Version Management

### Always Latest (Recommended)

```yaml
uses: FortTax/security-workflows/.github/workflows/reusable-security-scan.yml@main
```

### Pin to Specific Version

```yaml
uses: FortTax/security-workflows/.github/workflows/reusable-security-scan.yml@v1.0.0
```

## 🏢 Organization Setup

### 1. Set Organization Secrets

For organization-wide deployment:

- `SNYK_TOKEN` - Snyk API token
- `FOSSA_API_KEY` - FOSSA API key
- `SEMGREP_APP_TOKEN` - Semgrep app token

### 2. Repository Templates

Create repository templates with pre-configured security workflows.

## 📞 Support

- **Issues**:
  [Create issue](https://github.com/FortTax/security-workflows/issues/new)
- **Security Team**: security@forttax.com

---

_Maintained by FortTax - Providing enterprise-grade security scanning for any
repository._
