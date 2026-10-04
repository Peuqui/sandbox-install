#!/usr/bin/env bash
# One-time host setup for sandbox-install: the user may drive Incus, a
# storage pool and a NAT bridge for the sandbox containers.
#
#   sudo ./setup-incus.sh <user> <dns-server> [subnet]
#
#   <user>        account that will run sandbox-install (joins incus-admin)
#   <dns-server>  resolver the containers get, normally your LAN router
#   [subnet]      bridge address, default 10.99.0.1/24 — pick one nothing
#                 else on the machine uses (Docker, VPN, LAN)
#
# Needs Incus >= 7.0 (e.g. from https://github.com/zabbly/incus): with 6.0,
# Docker 29 inside the containers cannot start containers of its own.
set -euo pipefail

[ "$EUID" -eq 0 ] || { echo "run with sudo" >&2; exit 1; }
[ $# -ge 2 ] || { sed -n '5,13p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
SANDBOX_USER="$1"
DNS_SERVER="$2"
SUBNET="${3:-10.99.0.1/24}"

usermod -aG incus-admin "$SANDBOX_USER"

# dnsmasq runs DHCP only (port=0): a resolver already listening on all host
# addresses (Pi-hole, systemd-resolved stub on 0.0.0.0, ...) would otherwise
# block the bridge; containers ask <dns-server> directly.
incus admin init --preseed <<EOF
storage_pools:
- name: default
  driver: dir
networks:
- name: incusbr0
  type: bridge
  config:
    ipv4.address: $SUBNET
    ipv4.nat: "true"
    ipv6.address: none
    raw.dnsmasq: |-
      port=0
      dhcp-option=6,$DNS_SERVER
profiles:
- name: default
  devices:
    root:
      path: /
      pool: default
      type: disk
    eth0:
      name: eth0
      network: incusbr0
      type: nic
EOF

incus storage list
incus network list
echo "Done. $SANDBOX_USER is in incus-admin (takes effect on next login)."
