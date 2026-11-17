# Homelab & Cloud Infrastructure - davidnicolini.com.br

Infrastructure-as-Code (IaC) and idempotent provisioning scripts for my personal server (Debian 13 Trixie) and cloud-instance deployments. The setup hosts my portfolio (`davidnicolini.com.br`), Java / Spring Boot REST APIs, and PostgreSQL containers with zero exposed inbound ports on the router.

---

## Network & Zero-Trust Architecture

```mermaid
flowchart LR
    User([Internet / Client]) -->|HTTPS / TLS 1.3| CF[Cloudflare Edge & DNS<br/>Registro.br NS]
    
    subgraph ZeroTrust [Zero-Trust Encrypted Ingress]
        CF <-->|Outbound QUIC/HTTP2 Tunnel| CFD[cloudflared Daemon]
    end

    subgraph HomeServer [Bare-Metal Node - Lenovo IdeaPad 330 - Debian 13]
        CFD -->|localhost:80| NGINX[Nginx Reverse Proxy<br/>Security Headers & Routing]
        
        NGINX -->|/| STATIC[Static Portfolio<br/>davidnicolini.com.br]
        NGINX -->|/api/teampilot| DOCKER1[TeamPilot API<br/>Java 25 + Spring Boot 4]
        NGINX -->|/api/taskhub| DOCKER2[TaskHub API<br/>Java 17 + Spring Boot 3]
        
        DOCKER1 --> PG[(PostgreSQL 16)]
        DOCKER2 --> PG
        
        UFW[UFW Firewall<br/>Default Deny Incoming] -.->|Protects| HomeServer
        SSH[Hardened SSH<br/>Ed25519 Key Only] -.->|LAN Admin| HomeServer
    end
```

---

## Quick Provisioning (`bootstrap.sh`)

Used for rapid recovery or replicating the environment on a fresh Debian/Ubuntu install (bare-metal or cloud VPS):

```bash
git clone [https://github.com/davidnicolini/homelab-infrastructure.git](https://github.com/davidnicolini/homelab-infrastructure.git)
cd homelab-infrastructure
sudo ./scripts/bootstrap.sh
```

What the script executes:
1. Installs `Nginx`, `UFW`, and `Docker Engine + Compose`.
2. Clones the portfolio repository into `/var/www/davidnicolini.com.br` and applies `www-data` permissions.
3. Deploys the Nginx virtual host with security headers, Gzip, and reverse proxy paths (`/api/`) for Spring Boot services.
4. Applies SSHD hardening (`PermitRootLogin no`, `PasswordAuthentication no`) and enables UFW default-deny rules.
5. Installs `cloudflared` for outbound Zero-Trust tunneling.

---

## Repository Layout

```text
homelab-infrastructure/
├── nginx/sites-available/davidnicolini.conf  # Reverse proxy, Gzip & security headers
├── cloudflared/config.example.yml            # Sanitized Zero-Trust ingress template
├── security/
│   ├── 99-hardening.conf                     # SSH cryptographic key-only policy
│   └── ufw-rules.sh                          # Host firewall ruleset
└── scripts/
    ├── bootstrap.sh                          # Full idempotent server provisioner
    └── healthcheck.sh                        # Daemon, RAM, disk & HTTP status monitor
```

---

## Hardware & Stack

- **Node:** Lenovo IdeaPad 330-15IGM (Intel Celeron N4000, 4GB DDR4, 128GB SSD)
- **OS:** Debian 13 (Trixie) - headless minimal install
- **DNS & Ingress:** Registro.br -> Cloudflare DNS -> Cloudflare Tunnel (`systemd`)
- **Proxy & Runtime:** Nginx, Docker Compose, Java 17/25 (Spring Boot), PostgreSQL