# Hi, I'm Vamsi Krishna 👋

I come from 1.5 years in operations and I am now moving into DevOps. I understand how systems break, what it takes to keep them running, and why observability matters — because I've been on the other side dealing with it manually.

---

## 🛠️ What I've built

### Terminal-Based Linux Monitoring & Auto-Maintenance System

The first thing I wanted to understand was — how does a system actually get monitored? Not with a tool, but from scratch. So I built a terminal monitoring system in pure Bash that reads CPU, memory, disk, load, and network data directly from `/proc` and `/sys`.

It has a real-time color-coded dashboard, threshold alerting, self-healing that restarts crashed services, log rotation, daily reports, weekly maintenance, and security patching — all automated with cron.

It works. But it only works on the machine it runs on. You can't see anything from outside. You can't scale it. And if the machine restarts, the logs are gone.

That's what pushed me to build the next one.

**Tech:** `Bash` `Linux` `Cron` `Systemd`

🔗 [View Project](https://github.com/vamsikrishnamunukuti0410/Terminal-Based-Monitoring-Auto-Maintenance-System)

---

### Sentinel-Ops — Containerised Monitoring Agent

I wanted to take the same monitoring logic and ask — what if it runs inside a container on a real cloud server?

I containerised the Bash agent using Docker and ran it on AWS EC2. Used `--pid=host` so the container can see all real processes on the host. Split the work into two scripts: `doctor.sh` collects the metrics, `shield.sh` reads the logs and fires alerts.

Ran it as a non-root user inside Alpine Linux to keep the attack surface small. Added log rotation so it doesn't fill the disk on a t3.micro.

It ran. But I was still just reading logs manually. There was no way to query metrics over time, no dashboards, no history. If something spiked at 2am, I'd only know if I happened to check the log file.

That's the gap I wanted to close in the next one.

**Tech:** `Docker` `Bash` `Alpine Linux` `AWS EC2` `Cron`

🔗 [View Project](https://github.com/vamsikrishnamunukuti0410/Sentinel-Ops)

---

### Cloud-Native Linux Monitoring Platform

This is where I tried to build something that looks like real production monitoring.

I built a custom Prometheus exporter in Bash — the agent reads metrics from `/proc`, formats them in Prometheus exposition format, and serves them over HTTP on port 9100 using Netcat. No Node Exporter, no third-party agent.

Deployed it on Kubernetes/OpenShift — the monitoring agent, Prometheus, and Grafana each run as separate pods. Added PersistentVolumeClaims so data survives pod restarts. Built Grafana dashboards for CPU, memory, disk, load average, and disk I/O. Automated the full workflow with GitHub Actions — every push builds the image, pushes to Docker Hub, and redeploys on OpenShift.

It didn't go smoothly. Prometheus kept crashing because the container didn't have write permissions on `/prometheus`. PVCs were stuck in Pending because of `WaitForFirstConsumer` binding mode. OpenShift's random UID assignment broke filesystem permissions. I fixed all of them — and learned more from those failures than from the parts that worked first time.

**Tech:** `Bash` `Docker` `Kubernetes` `Red Hat OpenShift` `Prometheus` `Grafana` `GitHub Actions` `AWS EC2`

🔗 [View Project](https://github.com/vamsikrishnamunukuti0410/linux-monitoring-system)

---

## 🛠️ Skills

| Area | Tools |
|---|---|
| Scripting | Bash, Python |
| Containers | Docker, Docker Compose |
| Orchestration | Kubernetes, Red Hat OpenShift |
| Monitoring | Prometheus, Grafana, Redash |
| CI/CD | GitHub Actions |
| Cloud | AWS EC2 |
| OS | Linux (Debian, RHEL) |

---

## 📌 What I'm working on next

- **Terraform** — provision infrastructure as code instead of clicking through consoles
- **Helm** — manage Kubernetes deployments properly instead of raw manifests
- **ArgoCD** — GitOps-based continuous delivery, the next step beyond GitHub Actions on Kubernetes
- **Ansible** — automate server configuration and setup across multiple machines
- **Alertmanager** — complete the observability stack I already have with Prometheus
- **CI/CD improvements** — versioned image tagging, rollback mechanism, automated testing stage

---

## 📫 Reach me

- Email: vamsikrishna.munukuti@gmail.com
- LinkedIn: [linkedin.com/in/vamsikrishnamunukuti](https://linkedin.com/in/vamsikrishnamunukuti)
