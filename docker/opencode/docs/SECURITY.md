# OpenCode Agent Security Policy

## 🔒 Overview

The OpenCode agent operates in **DIAGNOSTIC MODE ONLY** to ensure maximum security while providing comprehensive infrastructure analysis capabilities. This document outlines the security policies, restrictions, and best practices implemented to prevent accidental or malicious infrastructure changes.

## Security Architecture

### Separation of Concerns

**OpenCode Agent (Diagnostic Mode)**
- Configuration analysis and validation
- State inspection and troubleshooting
- Read-only operations only
- No infrastructure modification capabilities

**Deployment Operations (Separate Containers)**
- Actual infrastructure deployment and modification
- Proper security controls and audit logging
- Formal change management processes
- Isolated from diagnostic operations

### Security Rationale

1. **Prevent Accidental Changes**: Eliminates risk of unintended infrastructure modifications during analysis
2. **Reduce Attack Surface**: Limits potential damage from compromised containers or malicious code
3. **Audit Compliance**: Clear separation between analysis and deployment for audit trails
4. **Principle of Least Privilege**: Only provides necessary permissions for diagnostic operations

## Command Restrictions

### Terraform Commands

#### ✅ ALLOWED (Read-Only Operations)
- `terraform plan` - Analyze proposed changes
- `terraform plan -destroy` - Analyze destruction impact
- `terraform show` - Display current state
- `terraform state show <resource>` - Show specific resource details
- `terraform state list` - List resources in state
- `terraform output` - Display output values
- `terraform validate` - Validate configuration syntax
- `terraform fmt` - Format configuration files
- `terraform version` - Show version information
- `terraform providers` - Show provider information

#### ❌ PROHIBITED (Destructive Operations)
- `terraform apply` - Infrastructure deployment
- `terraform destroy` - Infrastructure destruction
- `terraform import` - State modification
- `terraform state rm` - State manipulation
- `terraform state mv` - State manipulation
- `terraform taint` - Resource marking for replacement
- `terraform apply -replace` - Forced resource replacement
- `terraform state replace-provider` - Provider changes

### Shell Commands

#### ✅ ALLOWED (Safe Operations)
- File reading: `cat`, `head`, `tail`, `less`, `more`
- Directory listing: `ls`, `find` (with restrictions)
- Text processing: `grep`, `awk`, `sed` (read-only)
- File inspection: `file`, `stat`, `wc`
- Safe utilities: `echo`, `printf`, `date`, `pwd`
- Version checks: `--version`, `--help` flags

#### ❌ PROHIBITED (Dangerous Operations)
- File modification: `rm`, `mv`, `cp` (with system directories)
- Permission changes: `chmod`, `chown` (on system files)
- Network operations: `curl`, `wget` (to external URLs)
- Remote access: `ssh`, `scp`, `rsync`
- Privilege escalation: `sudo`, `su`
- Package installation: `apt install`, `pip install`, etc.
- Process manipulation: `kill`, `killall`
- System services: `systemctl`, `service`

