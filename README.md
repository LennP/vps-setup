# vps-setup

Sets up a fresh Ubuntu or Debian VPS for Dokploy.

## Install

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/LennP/vps-setup.git
cd vps-setup
sudo ./setup.sh
```

If you are already logged in as `root`, omit `sudo`.

The setup guides you through anything that needs your input, including creating and adding an SSH key.

## Run separately

Requirements only:

```bash
sudo ./setup/requirements/run.sh
```

Setup steps only:

```bash
sudo ./setup/steps/run.sh
```

Any individual check or step can also be run directly, for example:

```bash
sudo ./setup/steps/07_configure_firewall.sh
```
