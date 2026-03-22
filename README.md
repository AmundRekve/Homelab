# Homelab-DAM
 
> A personal homelab running on a single machine with 16GB RAM and 4 cores — a student build, because RAM doesn't grow on trees.
 

 
## Overview
 
This repository documents the services and infrastructure I run at home. Everything is a work in progress, and I continue to expand and improve the setup over time.
 

 
## Infrastructure
 
| Component | Details |
|-----------|---------|
| **Hypervisor** | Proxmox VE |
| **Orchestration** | Kubernetes (1 controller + 3 worker nodes) |
| **VPN** | WireGuard |
| **Hardware** | 16GB RAM, 4-core CPU |
 
All Kubernetes pod configurations can be found in the [`/kubernetes`](./kubernetes) directory.
 
---
 
## Services
### 🔷 Kubernetes
A self-hosted Kubernetes cluster managed through Proxmox, consisting of one controller node and three worker nodes. The cluster hosts the majority of my services and is managed via the Kubernetes Dashboard.
<img width="2686" height="557" alt="image" src="https://github.com/user-attachments/assets/40d5a010-e44e-491e-9d04-3b75773f8d88" />

### 🏠 Homepage
A custom homelab dashboard running on Kubernetes that provides a unified entry point to all services. It displays live system stats (CPU, RAM), quick-launch tiles for each service, and useful external links such as GitHub, Kubernetes docs, and Docker Hub.
<img width="1768" height="731" alt="image" src="https://github.com/user-attachments/assets/76c9112f-fb38-4777-9b31-78c92992e315" />

> Pod configuration for the homepage can be found in the [`/Homepage`](./kubernetes/Homepage) directory.
 
### 🖥️ Proxmox
The hypervisor layer that underpins the entire homelab. Proxmox VE is used to manage all virtual machines and LXC containers, providing a clean web UI for administration, snapshots, backups, and resource monitoring.
 
### ☁️ Nextcloud
A fully self-hosted cloud storage and file synchronization platform — essentially a private Dropbox that I own and control completely. Nextcloud is used to sync files between my phone and home computer without relying on any third-party cloud provider. Beyond file storage, Nextcloud also supports features like contacts, calendars, notes, and photo backups, making it a versatile personal cloud suite. All data stays local on my hardware.
> Pod configuration for nextcloud can be found in the [`/Nextcloud`](./kubernetes/Nextcloud) directory.

### 💪 Wger
A self-hosted workout management application used for planning, scheduling, and tracking training sessions. Wger provides a full-featured gym log with support for custom exercise definitions, workout routines, training calendars, and progress tracking over time. Running it locally means full data ownership with no subscription required.
> Pod configuration for the workout-manager can be found in the [`/Wger`](./kubernetes/Wger) directory.

### 📊 Pulse
A lightweight monitoring tool used to keep an eye on the health of containers and virtual machines that run outside of the Kubernetes cluster. Pulse provides an at-a-glance overview of resource usage, uptime, and service status across the homelab. It complements the Kubernetes Dashboard by covering the parts of the infrastructure that Kubernetes doesn't manage directly, such as standalone Docker containers and Proxmox VMs.
 
### 🔒 WireGuard
A modern, lightweight VPN that allows secure remote access to the homelab environment from anywhere. WireGuard is used to tunnel into the home network when away, giving full access to all internal services as if on the local network.
 
---
 
*This is a work in progress. Documentation will be updated as the homelab evolves.*
