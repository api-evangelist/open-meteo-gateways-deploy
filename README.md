# open-meteo-gateways-deploy

Single-host deploy for the three Open-Meteo gateway demos — [Tyk](https://github.com/api-evangelist/open-meteo-tyk-demo),
[KrakenD](https://github.com/api-evangelist/open-meteo-krakend), and
[agentgateway](https://github.com/api-evangelist/open-meteo-agentgateway) — behind one
[Caddy](https://caddyapp.com) reverse proxy with automatic TLS. This is what runs on the AWS
host that `weather-tyk` / `weather-krakend` / `weather-agentgateway.apievangelist.com` point at.

```bash
./bootstrap.sh     # clone the 3 sibling repos + docker compose up -d
```

Full runbook: **[DEPLOY.md](DEPLOY.md)**.

Part of *[The Consumer Decides the Gateway](https://apievangelist.com/2026/07/01/the-consumer-decides-the-gateway/)* —
same two keyless [Open-Meteo](https://open-meteo.com) upstreams, three gateways, one host.
