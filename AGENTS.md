# vps-setup implementation notes

## Execution model

- `setup.sh` runs `requirements/run.sh` and then `steps/run.sh`.
- Each `run.sh` executes numbered scripts in lexical order.
- Every numbered script is directly executable and must remain usable on its own when its prerequisites are present.
- Child-script failures must propagate without parent runners printing duplicate failure reports.

## Shared behavior

`lib/common.sh` owns presentation, logging, error handling, package-install helpers, state, child execution, and shared Dokploy firewall rules.

Successful command noise is written to `/var/log/vps-setup/<script>.log`. The terminal should only show concise progress. On failure, show the failing script, line, exit status context, recent log output, and log path, then stop immediately.

Persistent setup hints are stored under `/var/lib/vps-setup`.

## Supported hosts

- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS
- Debian 12

Keep host support intentionally limited to Ubuntu/Debian unless every affected step is implemented and tested for another distro family.

## Step order

1. Update system
2. Install base dependencies
3. Secure SSH
4. Enable unattended upgrades
5. Install/configure Fail2ban
6. Install Docker
7. Configure UFW + ufw-docker
8. Install Dokploy
9. Verify final state

The firewall step must leave Dokploy Traefik accessible when rerun after Dokploy is already installed. The Dokploy step must also ensure those rules are present after a fresh installation.
