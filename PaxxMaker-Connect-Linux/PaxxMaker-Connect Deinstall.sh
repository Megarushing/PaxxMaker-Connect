#!/usr/bin/env bash
# PaxxMaker-Connect deinstallieren / uninstall — im Terminal starten / run it in a terminal.
# Stops the program, removes the start-at-login service, the program and the
# menu entry, and asks whether the pairing code and working files should go too.
set -u
NAME="PaxxMaker-Connect"
TARGET="$HOME/.local/bin/$NAME"
DATA="${XDG_CONFIG_HOME:-$HOME/.config}/$NAME"
DESKTOP="${XDG_DATA_HOME:-$HOME/.local/share}/applications/paxxmaker-connect.desktop"
ICON="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/256x256/apps/paxxmaker-connect.png"
UNIT="paxxmaker-connect.service"

DE=0; case "${PAXX_LANG:-${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}}" in de*) DE=1;; esac
t()     { if [ "$DE" = 1 ]; then printf "%s" "$1"; else printf "%s" "$2"; fi }
bold()  { printf "\033[1m%s\033[0m\n" "$*"; }
ok()    { printf "  \033[32m✓\033[0m %s\n" "$*"; }
warn()  { printf "  \033[33m!\033[0m %s\n" "$*"; }
ask()   { local a; printf "  %s [%s] " "$1" "$(t "j/N" "y/N")"; read -r a; [[ "$a" == [jJyY]* ]]; }

[ -t 1 ] && clear
bold "$(t "PaxxMaker-Connect deinstallieren" "Uninstall PaxxMaker-Connect")"
echo
systemctl --user stop "$UNIT" 2>/dev/null
pkill -xf "$TARGET( .*)?" 2>/dev/null && sleep 1   # full command line: names are cut to 15 chars
if [ -x "$TARGET" ]; then
  # The program removes its own start-at-login service.
  "$TARGET" --uninstall 2>/dev/null
  rm -f "$TARGET" && ok "$(t "Gelöscht:" "Deleted:") $TARGET"
else
  warn "$(t "Kein installiertes Programm in ~/.local/bin gefunden." "No installed program found in ~/.local/bin.")"
fi
rm -f "$DESKTOP" "$ICON"
ok "$(t "Menüeintrag entfernt" "Menu entry removed")"
if command -v ufw >/dev/null 2>&1 && LC_ALL=C sudo -n ufw status 2>/dev/null | grep -q '8765/tcp'; then
  if ask "$(t "Firewall-Regel für Port 8765 entfernen? (sudo)" "Remove the firewall rule for port 8765? (sudo)")"; then
    sudo ufw delete allow 8765/tcp >/dev/null && ok "$(t "Firewall-Regel entfernt" "Firewall rule removed")"
  fi
fi
if [ -d "$DATA" ]; then
  echo
  if ask "$(t "Auch Kopplungscode und Arbeitsdateien löschen" "Also delete the pairing code and working files") ($DATA)?"; then
    rm -rf "$DATA"
    ok "$(t "Daten gelöscht — beim nächsten Installieren muss das iPhone neu gekoppelt werden" "Data deleted — the iPhone has to be paired again after the next install")"
  else
    ok "$(t "Daten behalten — eine Neuinstallation läuft mit demselben Kopplungscode weiter" "Data kept — a reinstall continues with the same pairing code")"
  fi
fi
echo
bold "$(t "Fertig." "Done.")"
