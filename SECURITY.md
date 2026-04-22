# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Do not open a public issue for security vulnerabilities.**

Instead, email: **branden@example.com** (or your preferred contact)

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if you have one)

### What to expect

- **Acknowledgment**: Within 48 hours
- **Updates**: Every 7 days until resolved
- **Fix timeline**: Depends on severity (critical issues within 7 days)
- **Credit**: You'll be credited in the release notes unless you prefer to remain anonymous

## Security Best Practices

When using this container:

1. **Never expose port 35001 to untrusted networks**
   - Use `kubectl port-forward` only during auth
   - Kill the port-forward immediately after authentication completes

2. **Protect your VPN config**
   - Store `.ovpn` files in Kubernetes Secrets, not ConfigMaps
   - Use RBAC to restrict access to the namespace

3. **Use least-privilege service accounts**
   - Don't run the pod with `privileged: true`
   - Only grant `NET_ADMIN` capability (required for TUN device)

4. **Rotate credentials regularly**
   - VPN certificates
   - SAML IdP tokens
   - Kubernetes secrets

5. **Monitor for suspicious activity**
   - Unexpected VPN disconnections
   - Failed auth attempts
   - Unusual traffic patterns

## Known Security Considerations

### TUN Device Requirement
The container needs `NET_ADMIN` capability to create a TUN interface. This is unavoidable for VPN operation but increases the attack surface. Mitigate by:
- Running in an isolated namespace
- Using network policies to limit pod-to-pod communication
- Auditing what services can access the VPN sidecar

### SAML Token Handling
SAML responses are written to `/saml-response.txt` during auth and deleted after connection. If the pod crashes mid-auth, the token file may persist. The entrypoint uses `0600` permissions to limit exposure.

### DNS Override
The entrypoint overwrites `/etc/resolv.conf` with Cloudflare DNS. If you need custom DNS, modify `entrypoint.sh` before building.

## Updates and Patching

- OpenVPN version: Defined in `Dockerfile` (`openvpn_version` arg)
- Base image: `ubuntu:22.04` (receives security updates from Canonical)
- Go version: Pinned to `1.21.0` in builder stage

To update dependencies:
```bash
# Update OpenVPN
docker build --build-arg openvpn_version=2.6.13 -t aws-vpn-client-saml:latest .

# Update base image
sed -i 's/ubuntu:22.04/ubuntu:24.04/g' Dockerfile
```

Subscribe to:
- [OpenVPN Security Advisories](https://openvpn.net/community-resources/openvpn-security-advisories/)
- [Ubuntu Security Notices](https://ubuntu.com/security/notices)

---

Thank you for helping keep this project secure.
