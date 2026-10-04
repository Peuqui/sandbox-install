# sandbox-install

[English](README.md)

Spielt die Installation eines Projekts so durch, wie ein Fremder sie erlebt:
ein frischer Linux-Systemcontainer, das **öffentliche** Repository, ein
normaler Benutzer mit sudo — nichts vom eigenen Rechner. So fällt auf, was nur
auf dem Entwicklerrechner funktioniert: ein Paket, das die Distribution anders
nennt, ein Werkzeug, das zufällig installiert ist, ein Schritt in falscher
Reihenfolge.

Ein Aufruf pro Lauf, kein Dienst. Protokolle landen in `logs/`, der Exit-Code
ist der des Installers.

## Was es gefunden hat

Am ersten Tag mit [AIfred-Intelligence](https://github.com/Peuqui/AIfred-Intelligence)
(Ubuntu 24.04): neun Installer-Fehler, keiner davon auf dem Entwicklerrechner
sichtbar — ein Compose-Paket, das es nur in Dockers eigener Paketquelle gibt,
`python3-venv` nie installiert, weil `import venv` auch ohne gelingt,
fehlendes `zstd`/`unzip`, nicht festgelegte Abhängigkeiten mit ungetesteten
Hauptversionen, Prüfungen, die scheitern, weil die frische `docker`-Gruppe noch
nicht wirkt, und ein Dienst, der startete, bevor seine Pflicht-Einstellung
geschrieben war.

## Voraussetzungen

- Linux mit **Incus ≥ 7.0** — z. B. von [Zabbly](https://github.com/zabbly/incus).
  Incus 6.0 (das Ubuntu-24.04-Paket) kann Docker 29 im Container nicht
  betreiben: runc scheitert an `open sysctl net.ipv4.ip_unprivileged_port_start`.
- Für `--gpu`: NVIDIA-GPU mit Treiber und
  [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
  auf dem Host.
- Plattenplatz: Eine volle Installation eines größeren Projekts belegt
  20–40 GB unter `/var/lib/incus`, bis der Container gelöscht ist.

## Einrichtung (einmalig)

```bash
git clone https://github.com/Peuqui/sandbox-install.git
cd sandbox-install
sudo ./setup-incus.sh "$USER" 192.168.1.1     # dein Router als DNS
```

`setup-incus.sh` nimmt dich in `incus-admin` auf und legt einen Speicher-Pool
und die Bridge `incusbr0` an (Standard `10.99.0.1/24`, NAT, kein IPv6). Ihr
dnsmasq macht nur DHCP, damit ein DNS-Server, der schon auf allen
Host-Adressen lauscht (etwa Pi-hole), nicht stört. Danach einmal ab- und
wieder anmelden — bis dahin startet sich `sandbox-install` selbst über
`sg incus-admin` neu.

## Benutzung

```bash
./sandbox-install [Optionen] <repo-url> -- <Installationsbefehl>
```

| Option | Bedeutung |
|---|---|
| `--distro IMAGE` | Incus-Image, Standard `ubuntu/24.04` (auch `debian/12`, `fedora/42`, `archlinux`, …) |
| `--env KEY=VALUE` | Variable für den Installationsbefehl (mehrfach) |
| `--gpu` | alle GPUs durchreichen — geteilt mit dem Host, laufende Last beachten |
| `--memory SIZE` / `--cpu N` | Grenzen, Standard `12GiB` / `8` |
| `--keep` | Container danach stehen lassen: `incus exec <name> -- su - tester` |

Beispiel:

```bash
./sandbox-install --gpu --keep \
    --env AIFRED_INSTALL_SYSTEMD=y --env AIFRED_INSTALL_USER=tester \
    https://github.com/Peuqui/AIfred-Intelligence.git -- ./scripts/install-all.sh
```

## Ablauf eines Laufs

1. Container aus dem Image starten (`security.nesting=true`, damit Docker darin läuft)
2. Nur bereitstellen, was ein Nutzer mitbringt: `git`, `sudo` und einen
   normalen Benutzer `tester` (sudo ohne Passwort, weil niemand tippt)
3. Mit `--gpu`: NVIDIA Container Toolkit nach NVIDIAs apt-Anleitung, im
   CDI-Modus als Docker-Standard-Laufzeit — Incus blendet
   `/proc/driver/nvidia/gpus` im Container nicht ein, das der alte Modus braucht
4. Repository als `tester` klonen, Installationsbefehl in einer Login-Shell
   ausführen. stdin ist leer: Der Installer muss ohne Rückfragen laufen
   (für jede Frage eine Umgebungsvariable anbieten)
5. Alles nach `logs/<container>.log`; Container löschen, außer mit `--keep`

## Lizenz

[PolyForm Noncommercial 1.0.0](LICENSE)
