#!/bin/sh

set -e

TARGET_DIR="$1"
SSH_DIR="$TARGET_DIR/etc/ssh"

# Generate SSH host keys at build time to not have to generate them
# on every first boot.  Keys are only generated if missing,
# so incremental builds keep the same keys.
# If ssh-keygen is not available, skip gracefully. OpenSSH's init
# script (S50sshd) will generate them on first boot instead.

if ! command -v ssh-keygen >/dev/null 2>&1; then
	echo "post_build.sh: ssh-keygen not found, skipping host key generation"
	echo "post_build.sh: keys will be generated on each boot"
	exit 0
fi

mkdir -p "$SSH_DIR"

for type in rsa ecdsa ed25519; do
	keyfile="$SSH_DIR/ssh_host_${type}_key"
	if [ ! -f "$keyfile" ]; then
		ssh-keygen -q -t "$type" -f "$keyfile" -N ""
		echo "post_build.sh: generated $keyfile"
	fi
done
