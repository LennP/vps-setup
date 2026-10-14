#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
standalone_header "SSH key"
require_root

user=$(setup_user)
home=$(user_home "$user")
[[ -n "$home" ]] || fail "Could not determine the home directory for $user"
authorized_keys="$home/.ssh/authorized_keys"

server_ip=""
if [[ -n ${SSH_CONNECTION:-} ]]; then
  read -r _ _ server_ip _ <<< "$SSH_CONNECTION"
fi
if [[ -z "$server_ip" ]]; then
  server_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
fi
[[ -n "$server_ip" ]] || fail "Could not determine this server's IP address"

save_state ssh_user "$user"
save_state server_ip "$server_ip"

if [[ -s "$authorized_keys" ]]; then
  done_msg "SSH key configured for $user"
  exit 0
fi

action "No SSH key is configured for $user yet."
printf '\nChoose a short name for this VPS.\n'
printf 'This becomes the SSH alias and key name on your computer.\n'
printf '%bExample: lenn creates Host lenn and ~/.ssh/id_lenn%b\n\n' "$GREY" "$RESET"
read -r -p 'VPS name: ' vps_name

if [[ -z "$vps_name" || ! "$vps_name" =~ ^[A-Za-z0-9._-]+$ ]]; then
  fail "Invalid name. Use only letters, numbers, dots, dashes, or underscores."
fi

save_state ssh_alias "$vps_name"

printf '\nRun the complete block below on your own computer.\n'
printf 'It requires no input and can be pasted in one go.\n\n'
printf '%b-------------------------------- local computer --------------------------------%b\n' "$GREY" "$RESET"
cat <<LOCAL_SCRIPT
bash <<'VPS_SSH_KEY'
set -Eeuo pipefail

name='$vps_name'
host='$server_ip'
user='$user'

ssh_dir="\$HOME/.ssh"
key_file="\$ssh_dir/id_\$name"
config_file="\$ssh_dir/config"

mkdir -p "\$ssh_dir"
chmod 700 "\$ssh_dir"
touch "\$config_file"
chmod 600 "\$config_file"

if [[ -e "\$key_file" || -e "\$key_file.pub" ]]; then
  if [[ -f "\$key_file" && -f "\$key_file.pub" ]]; then
    echo "Using existing SSH key: \$key_file"
  else
    echo "Error: only part of the key pair exists for \$key_file"
    exit 1
  fi
else
  ssh-keygen -q -t ed25519 -N '' -f "\$key_file" -C "\$name"
  echo "Created SSH key: \$key_file"
fi

if grep -Eq "^[[:space:]]*Host[[:space:]]+\$name([[:space:]]|\$)" "\$config_file"; then
  echo "SSH config already contains 'Host \$name'; leaving it unchanged."
else
  cat >> "\$config_file" <<CONFIG

Host \$name
  HostName \$host
  User \$user
  IdentityFile ~/.ssh/id_\$name
  IdentitiesOnly yes
CONFIG
  echo "Added SSH config entry: Host \$name"
fi

echo
echo "Copy this public key back to the waiting VPS setup:"
echo
cat "\$key_file.pub"
echo
echo "After setup finishes, test the connection with:"
echo "  ssh \$name"
VPS_SSH_KEY
LOCAL_SCRIPT
printf '%b--------------------------------------------------------------------------------%b\n' "$GREY" "$RESET"

printf '\nPaste the single public-key line printed by that script here.\n'
read -r -p '> ' public_key

case "$public_key" in
  ssh-ed25519\ *|ssh-rsa\ *|ecdsa-sha2-nistp256\ *|ecdsa-sha2-nistp384\ *|ecdsa-sha2-nistp521\ *) ;;
  *) fail "That does not look like a valid SSH public key. Nothing was changed." ;;
esac

install -d -m 700 -o "$user" -g "$(id -gn "$user")" "$home/.ssh"
touch "$authorized_keys"
if ! grep -Fxq "$public_key" "$authorized_keys"; then
  printf '%s\n' "$public_key" >> "$authorized_keys"
fi
chown "$user:$(id -gn "$user")" "$authorized_keys"
chmod 600 "$authorized_keys"

done_msg "SSH key added for $user"
warn "Keep this SSH session open until setup finishes and you have tested: ssh $vps_name"
