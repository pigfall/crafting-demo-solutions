#!/bin/bash

#!/bin/bash

# This script provisions the home directory for snapshots.
# It must NOT run as root.

function fatal() {
    echo "$@" >&2
    exit 1
}

[[ "$(id -u)" != "0" ]] || fatal "Must NOT run as root!"

mkdir -p ~/.config/direnv
cat <<EOF >~/.config/direnv/config.toml
[whitelist]
prefix = [
	"/home",
]
EOF

mkdir -p ~/.config ~/.local ~/.cache
mkdir -p ~/.snapshot
mkdir -p ~/.vscode-server/extensions
mkdir -p ~/.vscode-remote/extensions
cat <<EOF >~/.snapshot/includes.txt
.bashrc
.bash_logout
.profile
.config
.local
.cache
.snapshot
.vscode-server/extensions
.vscode-remote/extensions
EOF

cat <<EOF >~/.snapshot/excludes.txt
.ssh
.bash_history
.gitconfig
EOF

sed -i '/^# BEGIN-WORKSPACE-ENV/,/^# END-WORKSPACE-ENV/d' ~/.bashrc
cat <<EOF >>~/.bashrc
# BEGIN-WORKSPACE-ENV
eval "\$(direnv hook bash)"
# END-WORKSPACE-ENV
EOF
