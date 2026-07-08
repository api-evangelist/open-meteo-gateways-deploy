# Open-Meteo gateways — deploy

Reproducible deploy for the three Open-Meteo gateway demos that run on one AWS
host behind Caddy. This is the source of truth for what serves:

| Subdomain | Gateway | Surface |
|---|---|---|
| `weather-tyk.apievangelist.com` | Tyk OAS | REST — `/weather/forecast`, `/air/air-quality` |
| `weather-krakend.apievangelist.com` | KrakenD | REST — `/weather`, `/air-quality`, `/conditions` (merge) |
| `weather-agentgateway.apievangelist.com` | agentgateway | MCP-only — `POST /mcp` |

Each subdomain also serves a static landing page at `/` (from [`site/`](site/)), so
the bare domain is informative instead of a gateway 404.

## How it fits together

```
                         :443 (Caddy, auto-TLS)
   weather-tyk          ──────────────┐
   weather-krakend      ──────────────┤   host-based routing
   weather-agentgateway ──────────────┘
                                       │
   ┌───────────────────────────────────────────────────────┐
   │ compose network (no gateway ports published to host)   │
   │   tyk-gateway:8080   krakend:8080   agentgateway:3000   │
   │   tyk-redis:6379                                        │
   └───────────────────────────────────────────────────────┘
```

Only Caddy binds host ports (80/443). Tyk and KrakenD both listen on `:8080`
internally — that's fine because neither is published to the host; Caddy reaches
each container by service name on the compose network.

Gateway config is **mounted live from the three sibling repos** — this deploy
holds no copies. Clone them next to this directory:

```
demo/
├── open-meteo-gateways-deploy/   # this repo
├── open-meteo-tyk-demo/          # ../open-meteo-tyk-demo/tyk/{tyk.standalone.conf,apps/}
├── open-meteo-krakend/           # ../open-meteo-krakend/krakend.json
└── open-meteo-agentgateway/      # ../open-meteo-agentgateway/{config.yaml,openapi-*.json}
```

## First-time deploy

Prereqs on the host: `git`, `docker`, `docker compose`; ports 80/443 open; DNS
for the three subdomains already pointing at the host (required before Caddy can
obtain Let's Encrypt certs).

```bash
git clone https://github.com/api-evangelist/open-meteo-gateways-deploy.git
cd open-meteo-gateways-deploy
./bootstrap.sh          # clones the 3 sibling repos + docker compose up -d
```

## Day-to-day

```bash
docker compose up -d          # start / apply changes
docker compose ps             # status
docker compose logs -f caddy  # watch TLS + routing
docker compose down           # stop (keeps volumes: redis data, caddy certs)
```

To pick up a change to a gateway's config, pull that sibling repo and restart
just its container:

```bash
git -C ../open-meteo-krakend pull
docker compose up -d --force-recreate krakend
```

To change routing or a landing page, edit [`Caddyfile`](Caddyfile) / [`site/`](site/) here, then:

```bash
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile   # zero-downtime
# or: docker compose up -d --force-recreate caddy
```

## Verify

```bash
# Tyk (REST)
curl -s "https://weather-tyk.apievangelist.com/weather/forecast?latitude=40.7128&longitude=-74.006&current=temperature_2m&timezone=auto"
# KrakenD (declarative merge)
curl -s "https://weather-krakend.apievangelist.com/conditions?latitude=40.7128&longitude=-74.006"
# agentgateway (MCP) — landing page at /, MCP handshake at /mcp
curl -s -o /dev/null -w '%{http_code}\n' https://weather-agentgateway.apievangelist.com/   # 200 (landing)
npx @modelcontextprotocol/inspector   # connect to https://weather-agentgateway.apievangelist.com/mcp
```

## Notes / gotchas

- **agentgateway is MCP, not REST.** A bare `GET /mcp` returns `406` by design —
  MCP Streamable HTTP needs `POST` with `Accept: application/json, text/event-stream`.
  Caddy passes the `mcp-session-id` header and streams `text/event-stream` through unchanged.
- **agentgateway HTTPS upstreams** need a backend TLS policy (`backendTLS.insecure: true`
  here, because the two targets are different hosts) — that lives in the agentgateway repo's `config.yaml`.
- **Caddy volumes** `caddy-data` / `caddy-config` persist issued certificates — don't
  delete them casually or you'll re-hit Let's Encrypt rate limits.
- The old `weather.apievangelist.com` Cloudflare Worker custom domain was retired; the
  Worker (the "code gateway" companion) now lives only at
  `open-meteo-tyk-demo.kinlane.workers.dev` and is deployed separately with `wrangler deploy`.
