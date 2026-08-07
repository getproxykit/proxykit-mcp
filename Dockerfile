# Dockerfile for Glama (https://glama.ai/mcp/servers) introspection.
#
# proxykit-mcp is a stdio bridge to a local ProxyKit engine. It registers all
# tools and answers MCP initialize / tools/list WITHOUT an engine or token —
# the engine is only contacted when a tool is actually invoked. That is exactly
# what Glama's check needs: the server starts and responds to introspection.
#
# The binary is not built here (ProxyKit is proprietary); this pulls the
# published, checksum-pinned CLI archive from the release server and runs the
# proxykit-mcp it contains.

FROM debian:stable-slim

ARG PROXYKIT_VERSION=1.0.1
ARG TARGET=linux-amd64
# sha256 of proxykit-cli-${PROXYKIT_VERSION}-${TARGET}.tar.gz (published .sha256 sidecar)
ARG ARCHIVE_SHA256=a1c2a7d7b1f455642e0a372e02d9a064b883ddc6020046ac9c8a9e2c058e8d06

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    url="https://release.proxykit.net/v${PROXYKIT_VERSION}/cli/${TARGET}/proxykit-cli-${PROXYKIT_VERSION}-${TARGET}.tar.gz"; \
    curl -fsSL "$url" -o /tmp/cli.tar.gz; \
    echo "${ARCHIVE_SHA256}  /tmp/cli.tar.gz" | sha256sum -c -; \
    tar xzf /tmp/cli.tar.gz -C /tmp ./bin/proxykit-mcp; \
    install -m 0755 /tmp/bin/proxykit-mcp /usr/local/bin/proxykit-mcp; \
    rm -rf /tmp/cli.tar.gz /tmp/bin

# Enumerate every tier so introspection reports the full tool surface.
# Read-only is the safe default at runtime; this only affects what Glama lists.
ENV PROXYKIT_MCP_TIER=readonly,mutate,capture,analysis,replay

ENTRYPOINT ["proxykit-mcp"]
