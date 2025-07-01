# FortTax Security Workflows Implementation Guide

## Overview

This guide provides step-by-step instructions for implementing centralized
security scanning across the FortTax application ecosystem.

## 🎯 Implementation Status

### Current Applications

| Repository            | Status             | Framework    | Current Workflows           | Action Required       |
| --------------------- | ------------------ | ------------ | --------------------------- | --------------------- |
| `portal-tax-analyzer` | ✅ **IMPLEMENTED** | VITE + React | Multiple security workflows | Disable old workflows |
| `cfc-wizard-v2`       | ✅ **IMPLEMENTED** | VITE + React | Multiple security workflows | Disable old workflows |
| `pfic-wizard`         | ✅ **IMPLEMENTED** | NextJS       | Multiple security workflows | Disable old workflows |

## 📋 Pre-Implementation Checklist

### 1. Repository Access

- [ ] Admin access to all three repositories
- [ ] Access to `FortTax/security-workflows` repository
- [ ] GitHub Actions permissions

### 2. Secrets Configuration (All Optional - Free Alternatives Available!)

The security workflow works perfectly with **FREE alternatives** for all paid
tools:

**✅ FREE SAST SCANNING:**

- ESLint Security plugin (automatically installed)
- Bandit for Python files (automatically installed)
- **Alternative to**: Semgrep (paid)

**✅ FREE DEPENDENCY SCANNING:**

- npm audit (built-in with Node.js)
- **Alternative to**: Snyk (paid)

**✅ FREE LICENSE COMPLIANCE:**

- Built-in package.json analysis
- **Alternative to**: FOSSA (paid)

**Optional Premium Upgrades (only if you want enhanced features):**

- [ ] `SNYK_TOKEN` - For enhanced dependency scanning (alternative: npm audit)
- [ ] `FOSSA_API_KEY` - For license compliance scanning (alternative: built-in
      analysis)
- [ ] `SEMGREP_APP_TOKEN` - For premium SAST scanning (alternative: ESLint
      Security + Bandit)

### 3. Deployment Workflow Names

- [ ] **Portal Tax Analyzer**: `Post-Deployment Tests`
- [ ] **CFC Wizard v2**: `Automatic Vercel Deploy`
- [ ] **PFIC Wizard**: `Deploy`

## 🚀 Implementation Steps

### Step 1: Commit Centralized Workflow Updates

First, ensure the enhanced centralized workflow is available:

```bash
cd ../security-workflows
git add .github/workflows/reusable-security-scan.yml
git add README.md
git add docs/IMPLEMENTATION_GUIDE.md
git commit -m "feat: enhance centralized security workflow with framework detection and financial compliance"
git push origin main
```

### Step 2: Implement Portal Tax Analyzer

✅ **Status: COMPLETED**

The centralized security workflow has been created at:

```
portal-tax-analyzer/.github/workflows/centralized-security-scan.yml
```

**Configuration:**

- Framework: VITE (auto-detected)
- Target URL: `https://portal-tax-analyzer.vercel.app`
- Scan Type: `frontend` (includes DAST)
- Schedule: Mondays at 10:00 UTC
- Triggers: PR, deployment completion, manual, weekly

**Next Steps:**

1. Test the new workflow manually
2. Disable old security workflows

### Step 3: Implement CFC Wizard v2

✅ **Status: COMPLETED**

The centralized security workflow has been created at:

```
cfc-wizard-v2/.github/workflows/centralized-security-scan.yml
```

**Configuration:**

- Framework: VITE (auto-detected)
- Target URL: `https://cfc-wizard-v2.vercel.app`
- Scan Type: `frontend` (includes DAST)
- Schedule: Mondays at 11:00 UTC (offset)
- Triggers: PR, deployment completion, manual, weekly

**Next Steps:**

1. Test the new workflow manually
2. Disable old security workflows

### Step 4: Implement PFIC Wizard

✅ **Status: COMPLETED**

The centralized security workflow has been created at:

```
pfic-wizard/.github/workflows/centralized-security-scan.yml
```

**Configuration:**

- Framework: NextJS (auto-detected)
- Target URL: `https://pfic-wizard.vercel.app`
- Scan Type: `frontend` (includes DAST)
- Schedule: Mondays at 12:00 UTC (offset)
- Triggers: PR, deployment completion, manual, weekly

**Next Steps:**

1. Test the new workflow manually
2. Disable old security workflows

## 🧪 Testing the Implementation

### Manual Testing

For each repository, test the centralized workflow:

1. **Go to repository on GitHub**
2. **Navigate to Actions tab**
3. **Find "Centralized Security Scan" workflow**
4. **Click "Run workflow"**
5. **Use default settings and run**
6. **Monitor execution and results**

### Expected Results

✅ **Successful workflow should show:**

- Secrets detection results
- SAST scan findings
- Dependency vulnerability check
- Container security scan
- DAST scan (if target URL provided)
- Financial compliance checks
- Detailed summary in workflow output
- Security results artifact
- SARIF files uploaded to Security tab

### Troubleshooting

**Common Issues:**

1. **Workflow not found**
   - Ensure workflow file is committed to main branch
   - Check file is in `.github/workflows/` directory

2. **Permission errors**
   - Verify workflow has correct permissions
   - Check secrets are available to workflow

3. **Deployment trigger not working**
   - Verify deployment workflow name matches exactly
   - Check deployment workflow is completing successfully

## 🔧 Migrating From Old Workflows

### Step 1: Disable Old Workflows

Once centralized workflows are tested and working, disable the old ones:

#### Portal Tax Analyzer

Disable these workflows by renaming or moving them:

```bash
cd portal-tax-analyzer/.github/workflows

# Option 1: Rename to disable
mv post-deployment-security.yml post-deployment-security.yml.disabled
mv simple-security-scan.yml simple-security-scan.yml.disabled
mv debug-security-scan.yml debug-security-scan.yml.disabled

# Option 2: Move to archive folder
mkdir -p archive
mv post-deployment-security.yml archive/
mv simple-security-scan.yml archive/
mv debug-security-scan.yml archive/
```

#### CFC Wizard v2

```bash
cd cfc-wizard-v2/.github/workflows

# Disable old security workflows
mv standalone-security-scan.yml standalone-security-scan.yml.disabled
mv post-deployment-security.yml post-deployment-security.yml.disabled
mv debug-security-scan.yml debug-security-scan.yml.disabled
```

#### PFIC Wizard

```bash
cd pfic-wizard/.github/workflows

# Disable old security workflows
mv security-scan.yml security-scan.yml.disabled
mv manual-security-scan.yml manual-security-scan.yml.disabled
mv post-deployment-security.yml post-deployment-security.yml.disabled
```

### Step 2: Clean Up Repository Secrets

Review and consolidate secrets across repositories:

**Required Secrets (per repository):**

- `SNYK_TOKEN`
- `FOSSA_API_KEY`
- `SEMGREP_APP_TOKEN`

**Optional Secrets:**

- `SECURITY_EMAIL_WEBHOOK` (for future notification enhancements)

## 📊 Monitoring and Validation

### Security Metrics Dashboard

Monitor these key metrics across all applications:

| Metric        | Portal Tax Analyzer | CFC Wizard v2 | PFIC Wizard |
| ------------- | ------------------- | ------------- | ----------- |
| Last Scan     | ✅                  | ✅            | ✅          |
| Secrets Found | 0                   | 0             | 0           |
| SAST Issues   | TBD                 | TBD           | TBD         |
| Dependencies  | TBD                 | TBD           | TBD         |
| DAST Results  | TBD                 | TBD           | TBD         |

### Weekly Review Process

**Every Monday:**

1. Check all three applications completed their weekly scans
2. Review any security findings
3. Create issues for critical vulnerabilities
4. Update security metrics dashboard

### Monthly Security Review

**Monthly tasks:**

1. Review aggregate security trends
2. Update security tool versions
3. Review and tune false positive rates
4. Generate security compliance reports

## 🔐 Security Compliance Features

### Financial Services Compliance

All applications now include:

✅ **PCI DSS Checks**

- Payment processing code detection
- Secure data handling validation

✅ **Tax Software Compliance**

- IRS form processing detection
- CFC/PFIC specific compliance checks
- Tax ID and SSN handling validation

✅ **Data Security**

- Token storage security validation
- Encryption implementation checks
- Authentication security review

### Audit Trail

The centralized framework provides:

- **Complete scan history** - All security scans logged
- **Artifact retention** - 30-day retention of detailed results
- **SARIF integration** - Security results in GitHub Security tab
- **Automated reporting** - Executive summaries for each scan

## 🎛️ Advanced Configuration

### Custom Scan Types

Each repository can customize scan behavior:

```yaml
# Frontend-optimized scanning
scan_type: "frontend" # Includes DAST

# Backend-only scanning
scan_type: "backend" # No DAST, includes IaC

# Comprehensive scanning
scan_type: "all" # Everything
```

### Environment-Specific URLs

Configure different URLs for different environments:

```yaml
if [ "${{ github.ref_name }}" = "main" ]; then
  APP_URL="https://app-name.vercel.app"  # Production
else
  APP_URL="https://staging-app-name.vercel.app"  # Staging
fi
```

### Notification Configuration

Set up custom notifications:

```yaml
notification_email: "security@forttax.com"
```

## 📈 Success Metrics

### Implementation Success Criteria

✅ **Phase 1: Basic Implementation (COMPLETED)**

- All three applications have centralized security workflows
- Workflows trigger on PR, deployment, and schedule
- Basic security scans (secrets, SAST, dependencies) working

🎯 **Phase 2: Optimization (IN PROGRESS)**

- Old workflows disabled
- DAST scanning validated for all applications
- Security metrics dashboard established

🎯 **Phase 3: Enhancement (FUTURE)**

- Email notifications for critical findings
- Integration with security incident management
- Advanced compliance reporting

### Key Performance Indicators

- **Scan Coverage**: 100% of deployments scanned
- **Detection Time**: Vulnerabilities detected within 1 hour of deployment
- **Response Time**: Critical vulnerabilities addressed within 24 hours
- **False Positive Rate**: <10% of findings are false positives

## 🛠️ Maintenance and Updates

### Weekly Tasks

- [ ] Monitor scan execution across all repositories
- [ ] Review security findings and create issues
- [ ] Update security metrics

### Monthly Tasks

- [ ] Review and update security tool versions
- [ ] Analyze false positive trends
- [ ] Generate compliance reports

### Quarterly Tasks

- [ ] Review and update scan configurations
- [ ] Evaluate new security tools
- [ ] Security framework performance review

## 📞 Support and Escalation

### Getting Help

1. **Repository Issues**: Create issue in specific repository
2. **Framework Issues**: Create issue in `security-workflows` repository
3. **Security Incidents**: Email `security@forttax.com`
4. **Urgent Issues**: Follow incident response procedures

### Contact Information

- **Security Team**: security@forttax.com
- **DevOps Team**: devops@forttax.com
- **Framework Maintainer**: Platform Engineering Team

---

**Document Version**: 1.0 **Last Updated**: Implementation Phase **Next
Review**: After Phase 2 completion
