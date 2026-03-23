# 🚀 Linux Monitoring Platform (Kubernetes + Prometheus + Grafana)

## 📌 Overview

A cloud-native monitoring platform built with a custom Prometheus exporter, deployed on Kubernetes (OpenShift).

The system collects Linux metrics, exposes them over HTTP, stores them in Prometheus, and visualises them in Grafana — no third-party agent needed.

---

## 🎯 Objective

Build an end-to-end monitoring pipeline:

```
Linux Metrics → Custom Exporter → Prometheus → Grafana → Users
```

---

## 🏗️ Architecture

```
Linux System
     │
     ▼
Monitoring Agent (Custom Exporter)
     │
     ▼
Prometheus (Time-Series DB + PVC)
     │
     ▼
Grafana (Dashboards + PVC)
     │
     ▼
OpenShift Route (External Access)
```

---

## ⚙️ Components

| Component        | Technology      | Purpose                          |
|------------------|-----------------|----------------------------------|
| Monitoring Agent | Bash + Netcat   | Collect and expose system metrics |
| Prometheus       | prom/prometheus | Scrape and store metrics         |
| Grafana          | grafana/grafana | Visualisation                    |
| Kubernetes       | OpenShift       | Orchestration                    |
| Storage          | PVC (gp3)       | Persistent data                  |

---

## 🔧 Features

- Custom Prometheus exporter built from scratch
- Real-time Linux system monitoring
- Kubernetes-native deployment
- Persistent storage using PVC
- External access via OpenShift Route
- Grafana dashboards for live visualisation

---

## 📊 Metrics Collected

- CPU Usage
- Memory Usage
- Disk Usage
- Disk I/O
- Network Traffic
- Network Connections
- TCP Retransmissions
- Load Average

---

## 📸 Dashboards

**Grafana — EC2 Monitoring System**

CPU, Memory, Disk gauges + Load Average trend

![Grafana Dashboard](docs/screenshots/grafana-dashboard.png)

**Grafana — Extended view with Disk I/O**

![Grafana Dashboard Extended](docs/screenshots/grafana-dashboard-3.png)

**Prometheus — metrics being scraped live from the agent**

![Prometheus](docs/screenshots/prometheus-cpu.png)

---

## 📁 Project Structure

```
.
├── core/
│   ├── monitor.sh          # Collects CPU, memory, disk, load and network metrics
│   └── config.cfg          # All thresholds and settings in one place
│
├── exporter/
│   ├── metrics.sh          # Formats collected metrics for Prometheus
│   └── metrics_server.sh   # HTTP server that exposes metrics on port 9100
│
├── docker/
│   ├── Dockerfile          # Builds the monitoring agent container image
│   └── docker-compose.yml  # Runs the full stack locally
│
├── Kubernetes/
│   ├── monitoring-agent-deployment.yaml
│   ├── monitoring-agent-service.yaml
│   ├── prometheus-config.yaml
│   ├── prometheus-deployment.yaml
│   ├── prometheus-pvc.yaml
│   ├── prometheus-service.yaml
│   ├── grafana-deployment.yaml
│   └── grafana-pvc.yaml
│
├── archive/                # Original Bash-only version — kept for reference
│   ├── alerts.sh
│   ├── self_heal.sh
│   ├── log_rotation.sh
│   ├── maintenance.sh
│   ├── report.sh
│   ├── security_update.sh
│   └── setup_cron.sh
│
├── .gitignore
└── .github/
    └── workflows/
        └── deploy.yml      # CI/CD pipeline
```

---

## 🐳 Docker Setup

Container includes the following system tools:

- `procps`
- `iproute2`
- `sysstat`
- `netcat`

**Run locally with Docker Compose**

```bash
cd docker
docker-compose up
# Prometheus → http://localhost:9090
# Grafana    → http://localhost:3000  (admin / admin)
```

---

## ☸️ Kubernetes Deployment

### Resources Used

- Deployments
- Services (ClusterIP)
- ConfigMaps
- PersistentVolumeClaims
- OpenShift Route

### Deploy to OpenShift

```bash
oc login --token=<TOKEN> --server=<SERVER_URL>
oc apply -f Kubernetes/
oc get routes   # Get the external Grafana URL
```

---

## 🌐 Networking Design

| Component        | Exposure              |
|------------------|-----------------------|
| Monitoring Agent | Internal (ClusterIP)  |
| Prometheus       | Internal (ClusterIP)  |
| Grafana          | External (Route)      |

---

## 💾 Persistence Strategy

**Initial issue** — used `emptyDir`, data was lost on every pod restart.

**Fix** — replaced with PersistentVolumeClaims:

- Prometheus → `/prometheus`
- Grafana → `/var/lib/grafana`

---

## 🔁 CI/CD Pipeline

Every `git push` to `main` triggers the GitHub Actions workflow:

1. Build Docker image
2. Push image to Docker Hub
3. Install OpenShift CLI
4. Login to OpenShift using encrypted secrets
5. Update the deployment image
6. Restart and verify rollout

**Required GitHub secrets:**

- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`
- `OPENSHIFT_TOKEN`
- `OPENSHIFT_SERVER`
- `OPENSHIFT_NAMESPACE`

---

## 🧪 Validation

Verify the metrics endpoint is live inside the running pod:

```bash
kubectl exec -it <pod-name> -- curl localhost:9100
```

Also confirm:
- Prometheus targets show status **UP**
- Grafana dashboards show live data
- Restart a pod and confirm data is still there (PVC working)

---

## ⚠️ Challenges and Debugging

### 1. Image Pull Errors
Fixed by correcting Docker image tagging and push steps.

### 2. OpenShift Security Constraints
OpenShift assigns a random UID at runtime. Fixed filesystem permissions to handle this.

### 3. Prometheus CrashLoopBackOff
Root cause: no write permission on `/prometheus`. Fixed by mounting a writable volume.

### 4. PVC Pending State
Cause: `WaitForFirstConsumer` binding mode. Fixed by triggering pod scheduling.

---

## 📈 Key Learnings

- Kubernetes networking and service discovery
- Difference between `emptyDir` and PVC
- OpenShift security model (random UID)
- Debugging CrashLoopBackOff issues
- Stateful vs stateless workloads
- Monitoring architecture design

---

## 🚫 Current Limitations

- No Alertmanager — alerting not implemented
- No Grafana provisioning — dashboards are set up manually
- No Prometheus retention policy defined
- No backup strategy for stored data
- No versioned image tagging — currently using `latest`

---

## 🔮 Future Improvements

- Add Alertmanager for alerts
- Implement Grafana provisioning
- Define Prometheus retention policies
- Add backup and restore strategy
- Add versioned image tags and rollback mechanism

---

## 🧑‍💻 Author

Built as a hands-on DevOps project to understand monitoring systems, Kubernetes deployment, and production-grade debugging.
