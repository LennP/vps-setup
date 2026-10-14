# vps-setup implementation notes

## Execution model

- `setup.sh` runs `requirements/run.sh` and then `steps/run.sh`.
- Each `run.sh` executes numbered scripts in lexical order.
- Every numbered script is directly executable and must remain usable on its own when its prerequisites are present.
- Child-script failures must propagate without parent runners printing duplicate failure reports.

## Idempotency

- Every requirement and setup step must be safe to run repeatedly.
- Determine completion from the actual current system state; do not use marker/"done" flags to skip work.
- If the desired state is already satisfied, leave it unchanged and print a concise success message saying so.
- Only perform mutations, rewrites, service restarts, or installations when the current state differs from the desired state.
- Never remove or overwrite unrelated user configuration while reconciling a step. Prefer dedicated `vps-setup` drop-in files for managed configuration; firewall reconciliation must preserve unrelated UFW rules.
- Desired state includes persistence across reboot where applicable (for example kernel modules and sysctls), not only the current runtime state.
- Generic host requirements and system-configuration steps should remain independent of Dokploy where possible; application-specific decisions belong in the Dokploy step.

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
