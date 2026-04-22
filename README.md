# AWS VPN Client SAML (Docker/Kubernetes)

Containerized AWS Client VPN with SAML authentication support for Kubernetes deployments.

## Overview

This project packages the [aws-vpn-client](https://github.com/aws-vpn-client/aws-vpn-client) into a Docker container designed to run as a sidecar or standalone pod in Kubernetes. It handles SAML-based authentication through a lightweight HTTP server that captures the SAML response from your browser.

### Use Case

You have:
- AWS Client VPN endpoint with SAML authentication (e.g., Okta, Azure AD)
- Services running in Kubernetes that need to access resources behind the VPN
- No desire to install VPN clients on every developer machine

This container:
- Establishes the VPN tunnel from within your cluster
- Exposes the VPN connection to other pods via shared network namespace or service mesh
- Handles SAML auth interactively during pod startup

## Architecture

```
┌─────────────────────────────────────────────────────┐
│ Kubernetes Pod                                      │
│                                                     │
│  ┌─────────────────┐      ┌────────────────────┐  │
│  │ VPN Sidecar     │      │ Application        │  │
│  │                 │      │                    │  │
│  │ • OpenVPN       │◄────►│ Uses VPN network   │  │
│  │ • SAML Server   │      │                    │  │
│  │   (port 35001)  │      │                    │  │
│  └────────┬────────┘      └────────────────────┘  │
│           │                                         │
└───────────┼─────────────────────────────────────────┘
            │
            │ Port-forward for auth
            ▼
     ┌──────────────┐
     │   Browser    │
     │ (SAML login) │
     └──────────────┘
            │
            ▼
    ┌───────────────────┐
    │ AWS Client VPN    │
    │   Endpoint        │
    └───────────────────┘
```

## How It Works

1. **Container starts**: Launches a simple HTTP server on port 35001
2. **Initial connection attempt**: OpenVPN connects to AWS, receives SAML redirect URL
3. **User authenticates**: 
   - You port-forward `35001` to localhost
   - Open the SAML URL in your browser
   - Complete SSO + MFA
   - Browser POSTs SAML response back to the container
4. **VPN connects**: Container uses SAML response to complete auth and establish tunnel

## Prerequisites

- Kubernetes cluster
- AWS Client VPN configuration file (`.ovpn`)
- Docker (for building)

## Quick Start

### 1. Build the Image

```bash
# Set your registry
export REGISTRY=docker.io/brandencobb

# Build and push
chmod +x build.sh
./build.sh --push
```

### 2. Create Kubernetes Resources

#### ConfigMap (VPN Config)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: vpn-config
  namespace: your-namespace
data:
  vpn.conf: |
    # Paste your .ovpn file contents here
    client
    dev tun
    proto udp
    remote cvpn-endpoint-abc123.prod.clientvpn.us-west-2.amazonaws.com 443
    # ... rest of config
```

#### Deployment (Sidecar Pattern)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-vpn
  namespace: your-namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-with-vpn
  template:
    metadata:
      labels:
        app: app-with-vpn
    spec:
      containers:
      # Your application container
      - name: app
        image: your-app:latest
        # App will share VPN network namespace
        
      # VPN sidecar
      - name: vpn
        image: docker.io/brandencobb/aws-vpn-client-saml:latest
        securityContext:
          capabilities:
            add:
              - NET_ADMIN
        volumeMounts:
        - name: vpn-config
          mountPath: /vpn.conf
          subPath: vpn.conf
        ports:
        - containerPort: 35001
          name: saml
      volumes:
      - name: vpn-config
        configMap:
          name: vpn-config
```

#### Service (for Port-Forward)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: vpn-saml
  namespace: your-namespace
spec:
  selector:
    app: app-with-vpn
  ports:
  - port: 35001
    targetPort: 35001
    name: saml
```

### 3. Deploy and Authenticate

```bash
# Apply resources
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Watch the pod start
kubectl logs -f deployment/app-with-vpn -c vpn

# When you see "SAML AUTHENTICATION REQUIRED":
# Port-forward in another terminal
kubectl port-forward svc/vpn-saml 35001:35001

# Open the SAML URL from the logs in your browser
# Complete authentication

# VPN connects automatically after auth
```

## Configuration

### Environment Variables

None required. The container is configured via:
- `/vpn.conf` (mounted from ConfigMap)

### Security Context

The container **requires** `NET_ADMIN` capability to create the TUN device.

```yaml
securityContext:
  capabilities:
    add:
      - NET_ADMIN
```

### DNS

The entrypoint script sets DNS to Cloudflare (1.1.1.1) to prevent VPN from breaking cluster DNS. Adjust in `entrypoint.sh` if needed:

```bash
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 1.0.0.1" >> /etc/resolv.conf
```

## Troubleshooting

### Container crashes with "Failed to get SAML redirect URL"

**Cause**: Network connectivity issue or wrong VPN config

**Fix**:
- Verify VPN endpoint is reachable from cluster
- Check `vpn.conf` has correct `remote` line
- Ensure no firewall blocking UDP/443 (or your VPN port)

### "SAML Authentication timed out"

**Cause**: You didn't complete auth within 10 minutes

**Fix**:
- Delete the pod to restart
- Complete auth faster next time
- Increase timeout in `entrypoint.sh` (search for `wait_file "saml-response.txt" 600`)

### Port-forward fails

**Cause**: Service selector doesn't match pod labels

**Fix**:
```bash
# Port-forward directly to pod
kubectl port-forward pod/<pod-name> 35001:35001
```

### VPN connects but app can't reach internal resources

**Cause**: Routing issue or missing shared network namespace

**Fix**:
- Ensure sidecar pattern is used (containers in same pod share network)
- Check VPN routes: `kubectl exec -it <pod> -c vpn -- ip route`
- Verify app is using correct DNS/IPs

## Files

- `Dockerfile` — Multi-stage build (patches OpenVPN, compiles Go server)
- `server.go` — HTTP server that captures SAML response
- `entrypoint.sh` — Orchestrates auth flow and OpenVPN connection
- `build.sh` — Build/push helper script

## Credits

Based on [aws-vpn-client](https://github.com/aws-vpn-client/aws-vpn-client) by [samm-git](https://github.com/samm-git).

## License

MIT (see LICENSE file)

---

**Security Note**: This container handles SAML tokens. Do not expose port 35001 to untrusted networks. Use `kubectl port-forward` only during auth, then kill the forward.
