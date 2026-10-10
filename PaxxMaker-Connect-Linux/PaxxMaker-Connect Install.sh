#!/usr/bin/env bash
# PaxxMaker-Connect installieren / install — im Terminal starten / run it in a terminal.
#
# Takes the program next to this file (release archive) or from the project
# folder (src/build); otherwise builds it from source or downloads the latest
# GitHub release. Copies it to ~/.local/bin, adds a menu entry, checks
# OrcaSlicer / Snapmaker Orca and starts the program with the pairing page.
set -u
DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd || pwd)"
NAME="PaxxMaker-Connect"
BIN_DIR="$HOME/.local/bin"
TARGET="$BIN_DIR/$NAME"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICONS="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/256x256/apps"
UNIT="paxxmaker-connect.service"
TMP="$(mktemp -d /tmp/paxx-install.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

# German on a German system, English everywhere else.
DE=0; case "${PAXX_LANG:-${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}}" in de*) DE=1;; esac
t()     { if [ "$DE" = 1 ]; then printf "%s" "$1"; else printf "%s" "$2"; fi }
bold()  { printf "\033[1m%s\033[0m\n" "$*"; }
ok()    { printf "  \033[32m✓\033[0m %s\n" "$*"; }
warn()  { printf "  \033[33m!\033[0m %s\n" "$*"; }
fail()  { printf "\n  \033[31m✗ %s\033[0m\n\n" "$*"; exit 1; }
ask()   { local a; printf "  %s [%s] " "$1" "$(t "j/N" "y/N")"; read -r a; [[ "$a" == [jJyY]* ]]; }

[ -t 1 ] && clear
bold "$(t "PaxxMaker-Connect installieren" "Install PaxxMaker-Connect")"
echo

[ "$(uname -s)" = Linux ] || fail "$(t "Dieses Skript ist für Linux." "This script is for Linux.")"
case "$(uname -m)" in x86_64|amd64) ;; *) fail "$(t "Fertige Programme gibt es nur für x86_64 — bitte aus dem Quellcode bauen (src/build.sh)." "Ready-made builds are x86_64 only — please build from source (src/build.sh).")";; esac

# 1) Find the program
SRC=""; ICON=""
if [ -x "$DIR/$NAME" ]; then
  SRC="$DIR/$NAME"; ICON="$DIR/icon.png"
elif [ -x "$DIR/src/build/$NAME" ]; then
  SRC="$DIR/src/build/$NAME"; ICON="$DIR/src/assets/icon.png"
elif [ -f "$DIR/src/go.mod" ] && command -v go >/dev/null 2>&1; then
  echo "  $(t "Hier liegt der Quellcode. Das Programm wird jetzt gebaut (Go, etwa eine Minute)…" "This is the source code. Building the program now (Go, about a minute)…")"
  "$DIR/src/build.sh" >"$TMP/build.log" 2>&1 || { tail -20 "$TMP/build.log"; fail "$(t "Bauen fehlgeschlagen — siehe Meldungen oben." "Build failed — see the messages above.")"; }
  SRC="$DIR/src/build/$NAME"; ICON="$DIR/src/assets/icon.png"
else
  # No program and no Go: fetch the latest release (repo from git, else PAXX_REPO).
  REPO="${PAXX_REPO:-$(git -C "$DIR" remote get-url origin 2>/dev/null | sed -E 's#.*github.com[:/]##; s#\.git$##')}"
  [ -n "$REPO" ] || fail "$(t "Kein Programm gefunden. Bitte das Linux-Archiv von der Releases-Seite laden und darin diese Datei starten." "No program found. Please download the Linux archive from the Releases page and run this file from there.")"
  echo "  $(t "Lade das neueste Release von" "Downloading the latest release from") github.com/$REPO …"
  URL=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep -o '"browser_download_url": *"[^"]*Linux[^"]*\.tar\.gz"' | head -1 | sed -E 's/.*"(https[^"]*)"/\1/')
  [ -n "$URL" ] || fail "$(t "Kein Linux-Release gefunden. Bitte aus dem Quellcode bauen (Go installieren, dann erneut starten)." "No Linux release found. Please build from source (install Go, then run this again).")"
  curl -fSL --progress-bar "$URL" -o "$TMP/release.tar.gz" || fail "$(t "Download fehlgeschlagen." "Download failed.")"
  tar -xzf "$TMP/release.tar.gz" -C "$TMP" || fail "$(t "Archiv lässt sich nicht entpacken." "Cannot unpack the archive.")"
  SRC="$TMP/$NAME/$NAME"; ICON="$TMP/$NAME/icon.png"
  [ -x "$SRC" ] || fail "$(t "Im Archiv fehlt" "The archive is missing") $NAME."
fi
ok "$(t "Programm gefunden:" "Found the program:") $SRC"

# 2) Stop the running copy, copy, menu entry
if systemctl --user is-active --quiet "$UNIT" 2>/dev/null; then
  systemctl --user stop "$UNIT"
  ok "$(t "Laufender Dienst angehalten" "Running service stopped")"
fi
# Match the full command line: Linux cuts process names to 15 characters.
if pkill -xf "$TARGET( .*)?" 2>/dev/null; then sleep 1; ok "$(t "Laufende Version beendet" "Running copy quit")"; fi
mkdir -p "$BIN_DIR" "$APPS" "$ICONS"
install -m 755 "$SRC" "$TARGET" || fail "$(t "Kopieren nach" "Copying to") $TARGET $(t "fehlgeschlagen." "failed.")"
[ -f "$ICON" ] && install -m 644 "$ICON" "$ICONS/paxxmaker-connect.png"
cat > "$APPS/paxxmaker-connect.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$NAME
Comment=PaxxMaker app ↔ OrcaSlicer
Exec="$TARGET" --show-window
Icon=paxxmaker-connect
Terminal=false
Categories=Graphics;3DGraphics;
EOF
ok "$(t "Installiert nach" "Installed to") $TARGET"

# 3) OrcaSlicer / Snapmaker Orca
ORCA=""; SNAP=""
for c in "$HOME/Applications/OrcaSlicer.AppImage" "$HOME/.local/bin/OrcaSlicer.AppImage" /opt/OrcaSlicer/OrcaSlicer.AppImage \
         "$(command -v orca-slicer 2>/dev/null)" "$(command -v OrcaSlicer 2>/dev/null)" "$(command -v io.github.softfever.OrcaSlicer 2>/dev/null)"; do
  [ -n "$c" ] && [ -e "$c" ] && { ORCA="$c"; break; }
done
for c in "$HOME/Applications/SnapmakerOrca.AppImage" "$HOME/Applications/Snapmaker_Orca.AppImage" "$HOME/.local/bin/SnapmakerOrca.AppImage" \
         "$(command -v snapmaker-orca 2>/dev/null)" "$(command -v SnapmakerOrca 2>/dev/null)"; do
  [ -n "$c" ] && [ -e "$c" ] && { SNAP="$c"; break; }
done
[ -n "$ORCA" ] && ok "OrcaSlicer: $ORCA"
[ -n "$SNAP" ] && ok "Snapmaker Orca: $SNAP"
if [ -z "$ORCA" ] && [ -z "$SNAP" ]; then
  warn "$(t "Weder OrcaSlicer noch Snapmaker Orca gefunden — ohne sie kann nichts gesliced werden." "Neither OrcaSlicer nor Snapmaker Orca found — nothing can be sliced without one.")"
  echo "    $(t "AppImage nach ~/Applications legen, oder PAXX_ORCA / PAXX_SNAPMAKER_ORCA setzen." "Put the AppImage in ~/Applications, or set PAXX_ORCA / PAXX_SNAPMAKER_ORCA.")"
  if ask "$(t "Download-Seite von OrcaSlicer öffnen?" "Open the OrcaSlicer download page?")"; then xdg-open "https://github.com/OrcaSlicer/OrcaSlicer/releases" >/dev/null 2>&1 & fi
fi
SLICER=""
if [ -n "$ORCA" ] && [ -n "$SNAP" ]; then
  echo
  echo "  $(t "Beide sind installiert. Welcher soll slicen (Profile kommen aus demselben Programm)?" "Both are installed. Which one should slice (profiles come from the same program)?")"
  echo "    1) Snapmaker Orca"
  echo "    2) OrcaSlicer"
  printf "  [1/2] "; read -r a
  if [ "$a" = 2 ]; then SLICER="orca"; else SLICER="snapmaker_orca"; fi
fi

# 4) Firewall (only when ufw is active)
if command -v ufw >/dev/null 2>&1 && LC_ALL=C sudo -n ufw status 2>/dev/null | grep -q "Status: active"; then
  if ask "$(t "ufw ist aktiv. Port 8765/tcp und mDNS 5353/udp freigeben? (sudo)" "ufw is active. Allow port 8765/tcp and mDNS 5353/udp? (sudo)")"; then
    sudo ufw allow 8765/tcp >/dev/null && sudo ufw allow 5353/udp >/dev/null && ok "$(t "Firewall-Regeln angelegt" "Firewall rules added")"
  fi
fi

# 5) Start at login + start
echo
LOGIN="off"
if ask "$(t "Soll PaxxMaker-Connect beim Anmelden automatisch starten?" "Start PaxxMaker-Connect automatically at login?")"; then
  LOGIN="on"
  if [ "$(loginctl show-user "$USER" -p Linger --value 2>/dev/null)" != yes ] && \
     ask "$(t "Auch ohne Anmeldung starten, direkt nach dem Hochfahren? (für Server ohne Bildschirm)" "Also start without logging in, right after boot? (for a headless server)")"; then
    loginctl enable-linger "$USER" && ok "$(t "Start beim Hochfahren aktiv" "Start at boot enabled")"
  fi
fi
ARGS=(--login-item "$LOGIN")
[ -n "$SLICER" ] && ARGS+=(--slicer "$SLICER")
# Writes the settings (and the systemd unit when "on"), then quits at once.
"$TARGET" "${ARGS[@]}" --apply-only >/dev/null 2>&1
if [ "$LOGIN" = on ]; then
  systemctl --user start "$UNIT"
  sleep 1
  [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] && xdg-open "http://127.0.0.1:8765/" >/dev/null 2>&1 &
else
  setsid -f "$TARGET" --show-window >/dev/null 2>&1 < /dev/null
fi
echo
bold "$(t "Fertig." "Done.")"
IP=$(hostname -I 2>/dev/null | awk '{print $1}')
TOKEN="${XDG_CONFIG_HOME:-$HOME/.config}/$NAME/token"
for _ in 1 2 3 4 5 6 7 8 9 10; do [ -s "$TOKEN" ] && break; sleep 0.5; done
CODE=$(cat "$TOKEN" 2>/dev/null)
if [ "$DE" = 1 ]; then cat <<TXT
  PaxxMaker-Connect läuft jetzt. Die Kopplungsseite mit Code und QR-Code:
    http://127.0.0.1:8765/   (nur auf diesem Rechner)
  Kopplungscode: ${CODE:-?}   (auch in ~/.config/$NAME/token)
  • Auf dem iPhone/iPad: PaxxMaker › Slicer › „Per QR-Code verbinden“ — oder
    „Manuell verbinden“, diesen Rechner (${IP:-IP}) wählen und den Code eintippen.
TXT
else cat <<TXT
  PaxxMaker-Connect is running now. The pairing page with code and QR code:
    http://127.0.0.1:8765/   (on this computer only)
  Pairing code: ${CODE:-?}   (also in ~/.config/$NAME/token)
  • On the iPhone/iPad: PaxxMaker › Slicer › "Connect with QR code" — or
    "Connect manually", pick this computer (${IP:-IP}) and type the code.
TXT
fi
