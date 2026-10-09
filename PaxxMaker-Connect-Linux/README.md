# PaxxMaker-Connect for Linux

The link between the **PaxxMaker** app (iPhone/iPad) and the **OrcaSlicer or Snapmaker Orca
installed on your Linux PC**: place, rotate, scale and paint the model on the phone —
PaxxMaker-Connect has the slicer slice it in the background and sends the G-code back, and
the app passes it straight to the printer. The slicer itself is left untouched; everything
stays on your own network — no cloud, no account, no telemetry.

It is the Windows version's Go code built for Linux, plus Snapmaker Orca support. It also runs
on a headless server (no screen), as a systemd user service.

## Installation

**Requirements:** a 64-bit (x86_64) Linux with systemd ·
[OrcaSlicer](https://github.com/OrcaSlicer/OrcaSlicer/releases) and/or
[Snapmaker Orca](https://github.com/Snapmaker/OrcaSlicer/releases) — the AppImage in
`~/Applications`, or a package on `PATH` · PC and iPhone on the same network.

1. **Download:** get the latest `PaxxMaker-Connect-Linux-x.y.tar.gz` from the releases page and
   extract it.
2. **Install:** in a terminal, run `./"PaxxMaker-Connect Install.sh"`. It copies the program to
   `~/.local/bin`, adds a menu entry, finds the slicers and asks:
   - which slicer to use, when both are installed;
   - start at login (a systemd user service), and start at boot without logging in
     (`loginctl enable-linger`, for a headless server);
   - a firewall rule, only when `ufw` is active.
3. **Pair:** the pairing page opens at `http://127.0.0.1:8765/` with the **pairing code and QR
   code**. In PaxxMaker go to *Slicer › Connect with QR code* and scan it — or *Connect manually*,
   pick the PC from the network list and type the 6-character code. Without a screen, the code is
   in `~/.config/PaxxMaker-Connect/token`.

Start the slicer once and walk through its setup wizard with your printer first — the printer,
process and filament lists in the app come from it.

On a desktop with a tray, the program shows a cube icon with *Show pairing*, *Start at login*
and *Quit*. Starting it from the menu shows the pairing page again.

**Remove:** `./"PaxxMaker-Connect Deinstall.sh"`. It asks whether the pairing code and working
files (`~/.config/PaxxMaker-Connect`) go too.

## OrcaSlicer or Snapmaker Orca

Both work. Profiles and slicing always come from the same program:

| | Profiles from | Slices with |
|---|---|---|
| `snapmaker_orca` (default when installed) | `~/.config/Snapmaker_Orca` | Snapmaker Orca |
| `orca` | `~/.config/OrcaSlicer` | OrcaSlicer |

Change it later with `PaxxMaker-Connect --slicer orca` (or `snapmaker_orca`) while the program
is stopped, or for one run with `PAXX_APP=orca`. Other install places: set `PAXX_ORCA` or
`PAXX_SNAPMAKER_ORCA` to the program's path.

Linux-only details:

- Orca copies its vendor profiles to `~/.config/<slicer>/system` only when its window has been
  opened. When a profile inherits from one that is not there, PaxxMaker-Connect reads it from
  inside the AppImage (unpacked once to `~/.config/PaxxMaker-Connect/bundled`). Those profiles
  only complete `inherits` chains; they are not listed in the app.
- Snapmaker Orca's command line (2.4.0) crashes on an explicit prime-tower filament
  (`wipe_tower_filament`), and has no `--logfile`. PaxxMaker-Connect leaves the key out (the
  default, "auto", is the same) and catches the console output instead.

## What it does

Same as the Mac and Windows versions: service on port 8765, Bonjour `_paxxconnect._tcp`,
pairing by a 6-character code, profiles with their `inherits` chains resolved, the plate as 3MF
with transforms, head per object and painted faces, headless slicing, and the result read off
the G-code. Snapmaker U1: one head → `T0` is rewritten to the chosen head; several heads → four
filament profiles in head order, and the slicer does the tool changes and the prime tower.

What a running copy opens up: port 8765 on the local network (every request except the pairing
page needs the pairing code; the page itself answers only on `127.0.0.1`), and the pairing code
stored in `~/.config/PaxxMaker-Connect/token`.

## Folders

```
PaxxMaker-Connect Install.sh     ← run in a terminal: install
PaxxMaker-Connect Deinstall.sh   ← run in a terminal: remove
README.md
src/        Go source and build.sh
Release/    the finished archive (created by the build)
```

## Building it yourself

Go 1.26 or newer, no C compiler (the program is a static binary):

```
src/build.sh     # → src/build/PaxxMaker-Connect and Release/PaxxMaker-Connect-Linux-<version>.tar.gz
```

`PaxxMaker-Connect Install.sh` run from this folder also builds the program when Go is installed.

## Status

Beta — tested on Ubuntu 24.04 with OrcaSlicer 2.4.2 and Snapmaker Orca 2.4.0 AppImages and a Snapmaker
U1 (one and two heads). Bug reports are welcome as an issue; please include your distribution,
which slicer and its version, the printer and, for slicing errors, the message from the app
including its `Orca Exit` number.
