FROM ubuntu:22.04 AS builder

ARG openvpn_version="2.6.12"

WORKDIR /

RUN apt-get update && \
    apt-get install -y \
    curl \
    unzip \
    build-essential \
    autoconf \
    libgnutls28-dev \
    liblzo2-dev \
    libpam0g-dev \
    libtool \
    libssl-dev \
    net-tools \
    git \
    patch \
    wget \
    pkg-config \
    libnl-genl-3-dev \
    libcap-ng-dev

# Clone the latest aws-vpn-client repo
RUN git clone https://github.com/aws-vpn-client/aws-vpn-client.git /aws-vpn-client

# Download and build patched OpenVPN
RUN curl -L https://github.com/OpenVPN/openvpn/archive/v${openvpn_version}.zip -o openvpn.zip && \
    unzip openvpn.zip && \
    mv openvpn-${openvpn_version} openvpn

# Apply AWS patch
RUN cd openvpn && \
    patch -p1 < /aws-vpn-client/openvpn-v${openvpn_version}-aws.patch && \
    autoreconf -i -v -f && \
    ./configure --disable-lz4 && \
    make

# Install Go
RUN wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz

ENV PATH=$PATH:/usr/local/go/bin

# Copy and build SAML server
COPY server.go .
RUN go build server.go

FROM ubuntu:22.04

ENV TZ="America/Los_Angeles"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && \
    apt-get install -y \
    dnsutils \
    liblzo2-dev \
    openssl \
    net-tools \
    curl \
    iproute2 \
    libnl-genl-3-200 \
    libcap-ng0 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /openvpn/src/openvpn/openvpn /openvpn
COPY --from=builder /server /server
COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
