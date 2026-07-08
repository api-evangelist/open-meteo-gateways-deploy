# MCP endpoint for the Tyk demo.
#
# Tyk's api-to-mcp (https://github.com/TykTechnologies/api-to-mcp) turns an
# OpenAPI spec into MCP tools, but speaks MCP over stdio only. Tyk's own MCP
# docs say a stdio->HTTP bridge is required to host a stdio MCP server, so we
# front it with supergateway, exposing Streamable HTTP at /mcp.
#
# Notes learned the hard way:
#  - Debian base, NOT Alpine: a transitive dep of api-to-mcp (lit-ntml) runs a
#    `bash postinstall.bash`; Alpine has no bash -> install fails (code 127).
#  - LOCAL install + direct bin paths, NOT `npm i -g`: the global install trips
#    lit-ntml's postinstall (needs `zx`); a local project install does not.
FROM node:22-slim
WORKDIR /app
RUN npm init -y >/dev/null 2>&1 \
 && npm install @tyk-technologies/api-to-mcp@0.1.1 supergateway@3.4.3 \
 && npm cache clean --force

# The 2-operation OpenAPI (the Tyk REST surface) is mounted at /config/openapi.json.
# Tool calls target the Tyk gateway on the compose network, so the MCP surface is
# governed by Tyk exactly like the REST surface.
EXPOSE 8000
ENTRYPOINT ["node", "/app/node_modules/supergateway/dist/index.js", \
  "--stdio", "node /app/node_modules/@tyk-technologies/api-to-mcp/bin/api-to-mcp --spec /config/openapi.json --targetUrl http://tyk-gateway:8080", \
  "--outputTransport", "streamableHttp", \
  "--stateful", \
  "--streamableHttpPath", "/mcp", \
  "--port", "8000"]
