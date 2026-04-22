# Contributing to AWS VPN Client SAML

Thanks for your interest in contributing! This project welcomes issues, pull requests, and feedback.

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/BrandenCobb/aws-vpn-client-saml/issues) first
2. Use the bug report template
3. Include:
   - Your environment (Kubernetes version, OS, cloud provider)
   - Steps to reproduce
   - Expected vs actual behavior
   - Relevant logs (sanitize any sensitive data)

### Suggesting Features

1. Open an issue with the "enhancement" label
2. Describe the use case and problem it solves
3. Be open to discussion about scope and implementation

### Submitting Pull Requests

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test locally:
   ```bash
   ./build.sh
   # Deploy to a test cluster
   kubectl apply -f kubernetes-example.yaml
   ```
5. Commit with clear messages:
   ```
   Fix DNS timeout when VPN endpoint is unreachable
   
   - Increase initial connection timeout to 60s
   - Add better error message for network failures
   - Update troubleshooting docs
   ```
6. Push and open a PR against `master`
7. Respond to review feedback

### Code Standards

- **Shell scripts**: Use `shellcheck` to lint
- **Go code**: Run `go fmt` before committing
- **Dockerfile**: Keep layers minimal, use multi-stage builds
- **Documentation**: Update README.md if behavior changes

### Testing Checklist

Before submitting a PR, verify:
- [ ] Builds without errors: `./build.sh`
- [ ] SAML auth flow works end-to-end
- [ ] VPN connects successfully
- [ ] DNS resolution works from within the pod
- [ ] No secrets or credentials in code/logs
- [ ] Documentation reflects changes

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/aws-vpn-client-saml.git
cd aws-vpn-client-saml

# Build locally
./build.sh

# Test in Kubernetes
kubectl create namespace vpn-test
kubectl apply -f kubernetes-example.yaml -n vpn-test
kubectl logs -f deployment/app-with-vpn -c vpn -n vpn-test
```

## Questions?

Open an issue with the "question" label or start a discussion.

## Code of Conduct

Be respectful. No harassment, trolling, or personal attacks. If you see a problem, report it.

---

Thank you for helping make this project better!
