
# Homelab-DAM

> A personal homelab running on a single machine with 16GB RAM and 4 cores — a student build, because RAM doesn't grow on trees.

---

## Overview

This repository documents the services and infrastructure I run at home. Everything is a work in progress, and I continue to expand and improve the setup over time.

---

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
<img width="2686" height="557" alt="image" src="https://github.com/user-attachments/assets/4cc5cc80-d346-4c7b-bb55-dcdfa39585c8" />

### 🏠 Homepage
A custom homelab dashboard running on Kubernetes that provides a unified entry point to all services. It displays system stats (CPU, RAM), quick-launch tiles for each service, and useful external links such as GitHub, Kubernetes docs, and Docker Hub.
<img width="2022" height="1344" alt="image" src="https://github.com/user-attachments/assets/59794abc-f018-4f5e-aba3-1fe38d5c62ab" />
> Pod configuration for the homepage can be found in the [`/kubernetes`](./kubernetes) directory.

### 🔒 WireGuard
A lightweight VPN that allows secure remote access to the homelab environment from anywhere.

### ☁️ Nextcloud
A self-hosted file sync solution (think self-hosted Dropbox) used to transfer files between my phone and home computer.

### 📊 Pulse
A monitoring tool for tracking containers and VMs outside of Kubernetes.

### 🖥️ Proxmox
The hypervisor layer that underpins the entire homelab, hosting all VMs and LXC containers.

---

*This is a work in progress. Documentation will be updated as the homelab evolves.*
