# sandbox-install

Spielt die Installation eines Projekts in einem frischen Incus-Systemcontainer
durch — so, wie ein fremder Nutzer sie erlebt: öffentliches Repo, normaler
Benutzer mit sudo, nichts von diesem Rechner. Für alle Projekte und Agenten
auf dem Mini; ein Aufruf, kein Dienst.

```bash
./sandbox-install [Optionen] <repo-url> -- <Installationsbefehl>
```

| Option | Bedeutung |
|---|---|
| `--distro IMAGE` | Incus-Image, Standard `ubuntu/24.04` (auch `debian/12`, `fedora/42`, `archlinux`) |
| `--env KEY=VALUE` | Variable für den Installationsbefehl (mehrfach) |
| `--gpu` | alle GPUs durchreichen — geteilt mit dem Host, nicht während großer Modell-Ladevorgänge |
| `--memory SIZE` / `--cpu N` | Grenzen, Standard 12GiB / 8 |
| `--keep` | Container danach stehen lassen (`incus exec <name> -- su - tester`) |

Beispiel:

```bash
./sandbox-install --gpu https://github.com/Peuqui/whisper-stt.git -- 'docker compose up -d --build'
```

## Ablauf

1. Container aus dem Image starten (`security.nesting=true`, damit Docker darin läuft)
2. Vorausgesetzt wird nur, was ein Nutzer selbst mitbringt: `git`, `sudo` und
   ein normaler Benutzer `tester` (sudo ohne Passwort, weil niemand tippt)
3. Repo als `tester` klonen, Installationsbefehl in einer Login-Shell ausführen
   (stdin ist leer — der Installer muss ohne Rückfragen laufen können)
4. Gesamte Ausgabe nach `logs/<container>.log`, Exit-Code = der des Installers
5. Container löschen, außer mit `--keep`

## Voraussetzungen auf dem Host

Incus mit Netz `incusbr0` (10.99.0.0/24, DNS = FRITZ!Box 192.168.0.254) und Pool
`default` — eingerichtet mit `~/MiniPCLinux/scripts/incus-setup.sh`. Der
Aufrufer braucht die Gruppe `incus-admin`; fehlt sie in einer älteren Sitzung,
startet sich das Skript selbst über `sg` neu. Für `--gpu`: NVIDIA Container
Toolkit auf dem Host; im Container richtet `--gpu` das Toolkit im CDI-Modus ein (Incus blendet `/proc/driver/nvidia/gpus` nicht ein, das der alte Modus braucht). Incus ab 7.0 (Zabbly) — 6.0 aus Ubuntu verträgt sich nicht mit Docker 29 im Container.
