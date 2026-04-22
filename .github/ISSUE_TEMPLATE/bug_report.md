---
name: Bug Report
about: Report a bug or unexpected behavior
title: '[BUG] '
labels: bug
assignees: ''

---

## Description
A clear description of what the bug is.

## Environment
- Kubernetes version: (e.g., 1.28.3)
- Container runtime: (e.g., containerd, Docker)
- Cloud provider: (e.g., AWS EKS, GKE, self-hosted)
- Image version: (e.g., `brandencobb/aws-vpn-client-saml:latest` or specific tag)

## Steps to Reproduce
1. Deploy with this config: (attach or paste sanitized YAML)
2. Run this command: `kubectl ...`
3. Observe this behavior: ...

## Expected Behavior
What should happen?

## Actual Behavior
What actually happens?

## Logs
```
(Paste relevant logs from `kubectl logs -f deployment/app-with-vpn -c vpn`)
⚠️ Sanitize any secrets, hostnames, or sensitive data
```

## Additional Context
- VPN endpoint region/config
- SAML IdP used (e.g., Okta, Azure AD)
- Any custom modifications to entrypoint.sh or Dockerfile
- Screenshots (if applicable)

## Checklist
- [ ] I've checked existing issues for duplicates
- [ ] I've sanitized all sensitive data from logs/config
- [ ] I've tested with the latest image tag
