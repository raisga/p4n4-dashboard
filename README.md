# p4n4-dashboard

A static HTML dashboard for the [p4n4](https://p4n4.com) platform. Provides a single-page launcher with direct links to all running Docker services across the IoT, AI, and Edge stacks.

## Usage

Open `index.html` directly in your browser — no build step or server required.

```bash
open index.html        # macOS
xdg-open index.html    # Linux
```

Or serve it locally alongside your stacks:

```bash
python3 -m http.server 8888
# → http://localhost:8888
```

## Services

| Stack | Service | URL |
|-------|---------|-----|
| IoT | Grafana | http://localhost:3000 |
| IoT | Node-RED | http://localhost:1880 |
| IoT | InfluxDB | http://localhost:8086 |
| IoT | MQTT | `localhost:1883` (TCP only) |
| AI | Ollama | http://localhost:11434 |
| AI | Letta | http://localhost:8283 |
| AI | n8n | http://localhost:5678 |
| Edge | EI Runner | http://localhost:8080 |
| Gateway | p4n4-api | http://localhost:8000 |
| Gateway | Swagger UI | http://localhost:8000/swagger-ui |

## Stack startup order

The dashboard links assume all stacks are running. Start them in dependency order:

```bash
p4n4 up --all
# or manually:
cd p4n4-iot   && docker compose up -d
cd p4n4-ai    && docker compose up -d
cd p4n4-edge  && docker compose up -d
cd p4n4-api   && docker compose up -d
```

## Structure

```
p4n4-dashboard/
└── index.html    # self-contained — inline CSS/JS, no dependencies
```

## License

See [LICENSE](./LICENSE).