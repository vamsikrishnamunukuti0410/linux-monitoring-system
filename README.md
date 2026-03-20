# Cloud-Native Linux Monitoring Platform

A Bash-based Linux monitoring agent evolved into a containerised observability stack with Prometheus, Grafana, and OpenShift.

---

## Stack

- **Agent** — Bash + Netcat (port 9100)
- **Monitoring** — Prometheus + Grafana
- **Container** — Docker (Ubuntu-slim)
- **Orchestration** — Kubernetes / Red Hat OpenShift
- **CI/CD** — GitHub Actions

---

## Architecture

```
/proc filesystem → monitor.sh → metrics.sh → Prometheus (:9090) → Grafana (:3000)
                                    ↑
                          metrics_server.sh (nc :9100)
```

---

## Project Structure

```
.
├── core/
│   ├── monitor.sh        # CPU, memory, disk collection
│   ├── self_heal.sh      # Service watchdog
│   ├── log_rotation.sh   # Log management
│   └── config.cfg
├── exporter/
│   ├── metrics.sh        # Prometheus exposition format
│   └── metrics_server.sh # Netcat HTTP listener
├── docker/
│   └── Dockerfile
├── kubernetes/
│   ├── prometheus-deployment.yaml
│   ├── prometheus-pvc.yaml
│   ├── grafana-deployment.yaml
│   ├── grafana-pvc.yaml
│   ├── services.yaml
│   └── routes.yaml
└── .github/
    └── workflows/
        └── deploy.yml
```

---

## Quick Start

**Run locally**
```bash
bash exporter/metrics_server.sh
# Metrics available at http://localhost:9100/metrics
```

**Build Docker image**
```bash
docker build -t <your-user>/linux-monitor:latest -f docker/Dockerfile .
docker push <your-user>/linux-monitor:latest
```

**Deploy to OpenShift**
```bash
oc login --token=<TOKEN> --server=<SERVER_URL>
oc apply -f kubernetes/
oc get routes   # Get Grafana external URL
```

---

## Key Features

- **Custom exporter** — serves Prometheus metrics using only Bash and Netcat; no third-party agent required
- **Self-healing** — auto-restarts crashed services with a retry limit (`MAX_RESTART_RETRIES=3`); escalates to CRITICAL after three failures
- **Persistent storage** — Prometheus and Grafana data backed by PVCs; survives pod restarts
- **CI/CD pipeline** — every `git push` builds, pushes, and redeploys via GitHub Actions using encrypted secrets

---

## License

MIT
