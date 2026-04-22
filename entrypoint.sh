#!/bin/bash

set -e

# Set DNS to Cloudflare (prevents VPN from breaking DNS)
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 1.0.0.1" >> /etc/resolv.conf

echo "Starting SAML server on 0.0.0.0:35001"
/server &

cp /vpn.conf /vpn.modified.conf

sed -i '/^auth-user-pass.*$/d' /vpn.modified.conf
sed -i '/^auth-federate.*$/d' /vpn.modified.conf
sed -i '/^auth-retry.*$/d' /vpn.modified.conf

echo "" >> /vpn.modified.conf
echo "script-security 2" >> /vpn.modified.conf

# Add Starfield root certificate (required for AWS)
export CERT="-----BEGIN CERTIFICATE-----
MIID7zCCAtegAwIBAgIBADANBgkqhkiG9w0BAQsFADCBmDELMAkGA1UEBhMCVVMx
EDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNjb3R0c2RhbGUxJTAjBgNVBAoT
HFN0YXJmaWVsZCBUZWNobm9sb2dpZXMsIEluYy4xOzA5BgNVBAMTMlN0YXJmaWVs
ZCBTZXJ2aWNlcyBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAtIEcyMB4XDTA5
MDkwMTAwMDAwMFoXDTM3MTIzMTIzNTk1OVowgZgxCzAJBgNVBAYTAlVTMRAwDgYD
VQQIEwdBcml6b25hMRMwEQYDVQQHEwpTY290dHNkYWxlMSUwIwYDVQQKExxTdGFy
ZmllbGQgVGVjaG5vbG9naWVzLCBJbmMuMTswOQYDVQQDEzJTdGFyZmllbGQgU2Vy
dmljZXMgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBHMjCCASIwDQYJKoZI
hvcNAQEBBQADggEPADCCAQoCggEBANUMOsQq+U7i9b4Zl1+OiFOxHz/Lz58gE20p
OsgPfTz3a3Y4Y9k2YKibXlwAgLIvWX/2h/klQ4bnaRtSmpDhcePYLQ1Ob/bISdm2
8xpWriu2dBTrz/sm4xq6HZYuajtYlIlHVv8loJNwU4PahHQUw2eeBGg6345AWh1K
Ts9DkTvnVtYAcMtS7nt9rjrnvDH5RfbCYM8TWQIrgMw0R9+53pBlbQLPLJGmpufe
hRhJfGZOozptqbXuNC66DQO4M99H67FrjSXZm86B0UVGMpZwh94CDklDhbZsc7tk
6mFBrMnUVN+HL8cisibMn1lUaJ/8viovxFUcdUBgF4UCVTmLfwUCAwEAAaNCMEAw
DwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYEFJxfAN+q
AdcwKziIorhtSpzyEZGDMA0GCSqGSIb3DQEBCwUAA4IBAQBLNqaEd2ndOxmfZyMI
bw5hyf2E3F/YNoHN2BtBLZ9g3ccaaNnRbobhiCPPE95Dz+I0swSdHynVv/heyNXB
ve6SbzJ08pGCL72CQnqtKrcgfU28elUSwhXqvfdqlS5sdJ/PHLTyxQGjhdByPq1z
qwubdQxtRbeOlKyWN7Wg0I8VRw7j6IPdj/3vQQF3zCepYoUz8jcI73HPdwbeyBkd
iEDPfUYd/x7H4c7/I9vG+o1VTqkC50cRRj70/b17KSa7qWFiNyi2LSr2EIZkyXCn
0q23KXB56jzaYyWf/Wi3MOxw+3WKt21gZ7IeyLnp2KhvAotnDU0mV3HaIPzBSlCN
sSi6
-----END CERTIFICATE-----"

perl -i -0pe '$count = 0; s/-----BEGIN.*?-----END CERTIFICATE-----/(++$count == 3)?"$ENV{'CERT'}":$&/gesm;' /vpn.modified.conf

VPN_HOST=$(cat /vpn.modified.conf | grep 'remote ' | cut -d ' ' -f2)
PORT=$(cat /vpn.modified.conf | grep 'remote ' | cut -d ' ' -f3)
PROTO=$(cat /vpn.modified.conf | grep "proto " | cut -d " " -f2)

echo "Connecting to $VPN_HOST on port $PORT/$PROTO"
wait_file() {
	local file="$1"; shift
	local wait_seconds="${1:-10}"; shift # 10 seconds as default timeout
	until test $((wait_seconds--)) -eq 0 -o -f "$file" ; do sleep 1; done
	((++wait_seconds))
}

# create random hostname prefix for the vpn gw
RAND=$(openssl rand -hex 12)

# resolve manually hostname to IP, as we have to keep persistent ip address
SRV=$(dig a +short "${RAND}.${VPN_HOST}"|head -n1)
sed -i '/^remote .*$/d' /vpn.modified.conf
sed -i '/^remote-random-hostname.*$/d' /vpn.modified.conf

# cleanup
rm -f saml-response.txt
echo "Getting SAML redirect URL from the AUTH_FAILED response (host: ${SRV}:${PORT})..."

# Capture all output first, then filter
OVPN_FULL_OUT=$(timeout 30 /openvpn --config /vpn.modified.conf --verb 3 \
	--proto "$PROTO" --remote "${SRV}" "${PORT}" \
	--auth-user-pass <( printf "%s\n%s\n" "N/A" "ACS::35001" ) \
	2>&1 || true)

echo "OpenVPN output received, parsing..."
OVPN_OUT=$(echo "$OVPN_FULL_OUT" | grep AUTH_FAILED,CRV1 || true)

if [ -z "$OVPN_OUT" ]; then
	echo "ERROR: Failed to get SAML redirect URL from VPN endpoint"
	echo "OpenVPN output was:"
	echo "$OVPN_FULL_OUT" | head -50
	echo "This could mean:"
	echo "  - Network connectivity issue"
	echo "  - VPN endpoint is unreachable"
	echo "  - Wrong VPN configuration"
	exit 1
fi
echo $OVPN_OUT

URL=$(echo "$OVPN_OUT" | grep -Eo 'https://.+')
echo ""
echo "==============================================================================="
echo "SAML AUTHENTICATION REQUIRED"
echo "==============================================================================="
echo ""
echo "Step 1: Port-forward the SAML server to your local machine:"
echo ""
echo "  kubectl port-forward <pod-name> 35001:35001"
echo ""
echo "Step 2: Open this URL in your browser and log in:"
echo ""
echo "  $URL"
echo ""
echo "Step 3: Complete authentication (SAML + MFA)"
echo ""
echo "The VPN will connect automatically after successful authentication."
echo "Waiting up to 10 minutes for authentication..."
echo "==============================================================================="
echo ""
sleep 1
wait_file "saml-response.txt" 600 || {
	echo "SAML Authentication timed out"
	exit 1
}

# get SID from the reply
VPN_SID=$(echo "$OVPN_OUT" | awk -F : '{print $7}')

echo "Running OpenVPN."

# Finally OpenVPN with a SAML response we got
# Delete saml-response.txt after connect
exec /openvpn --config /vpn.modified.conf \
	--verb 3 --auth-nocache --inactive 3600 \
	--proto $PROTO --remote $SRV $PORT \
	--keepalive 10 60 \
	--route-up '/bin/rm saml-response.txt' \
	--auth-user-pass <( printf "%s\n%s\n" "N/A" "CRV1::${VPN_SID}::$(cat saml-response.txt)" )
