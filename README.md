# sandbox-install

[Deutsch](README.de.md)

Run a project's installation the way a stranger experiences it: a fresh Linux
system container, the **public** repository, a normal user with sudo — nothing
from your own machine. It finds what only works on the developer's box: a
package your distribution names differently, a tool your system happens to
have, a step that runs in the wrong order.

One command per run, no service. Logs go to `logs/`, the exit code is the
installer's.

## What it found

The first day on [AIfred-Intelligence](https://github.com/Peuqui/AIfred-Intelligence)
(Ubuntu 24.04): nine installer bugs, none of them visible on the development
machine — a compose plugin package that only exists in Docker's own apt repo,
`python3-venv` never installed because `import venv` succeeds without it,
missing `zstd`/`unzip`, unpinned dependencies pulling untested major versions,
checks failing because a fresh `docker` group membership is not active yet,
and the service starting before its required setting was written.

## Requirements

- Linux with **Incus ≥ 7.0** — e.g. from [Zabbly](https://github.com/zabbly/incus).
  Incus 6.0 (Ubuntu 24.04's own package) cannot run Docker 29 inside a
  container: runc fails with `open sysctl net.ipv4.ip_unprivileged_port_start`.
- For `--gpu`: an NVIDIA GPU with driver and the
  [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
  on the host.
- Disk space: a full install of a larger project can take 20–40 GB in
  `/var/lib/incus` until the container is deleted.

## Setup (once)

```bash
git clone https://github.com/Peuqui/sandbox-install.git
cd sandbox-install
sudo ./setup-incus.sh "$USER" 192.168.1.1     # your LAN router as DNS
```

`setup-incus.sh` adds you to `incus-admin` and creates a storage pool and the
bridge `incusbr0` (default `10.99.0.1/24`, NAT, no IPv6). Its dnsmasq only
does DHCP, so a resolver already listening on all host addresses (Pi-hole,
for instance) does not get in the way. Log out and back in afterwards — until
then `sandbox-install` re-runs itself through `sg incus-admin`.

## Usage

```bash
./sandbox-install [options] <repo-url> -- <install command>
```

The install command is one argument (a shell command line, e.g. `"make && make install"`) or a
command with its arguments, kept as given: `-- bash -c "$(cat steps.sh)"` runs the whole script.

| Option | Meaning |
|---|---|
| `--branch NAME` | clone this branch instead of the default one — test a change before it reaches main |
| `--distro IMAGE` | Incus image, default `ubuntu/24.04` (also `debian/12`, `fedora/42`, `archlinux`, …) |
| `--env KEY=VALUE` | variable for the install command (repeatable) |
| `--gpu` | pass all GPUs through — shared with the host, mind running workloads |
| `--memory SIZE` / `--cpu N` | limits, default `12GiB` / `8` |
| `--keep` | keep the container afterwards: `incus exec <name> -- su - tester` |

Example:

```bash
./sandbox-install --gpu --keep \
    --env AIFRED_INSTALL_SYSTEMD=y --env AIFRED_INSTALL_USER=tester \
    https://github.com/Peuqui/AIfred-Intelligence.git -- ./scripts/install-all.sh
```

## What a run does

1. Starts a container from the image (`security.nesting=true`, so Docker runs inside)
2. Provides only what a user brings along: `git`, `sudo` and a normal user
   `tester` (passwordless sudo, nobody is there to type)
3. With `--gpu`: the NVIDIA Container Toolkit per NVIDIA's apt instructions,
   in CDI mode as Docker's default runtime — Incus does not expose
   `/proc/driver/nvidia/gpus` inside the container, which the legacy mode needs
4. Clones the repository as `tester` and runs the install command in a login
   shell. stdin is empty: the installer has to run without questions (offer
   environment variables for every prompt)
5. Writes everything to `logs/<container>.log`; deletes the container unless `--keep`

## License

[PolyForm Noncommercial 1.0.0](LICENSE)
