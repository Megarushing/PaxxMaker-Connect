//go:build linux

package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

// Start at login: a systemd user service — no root, and with
// `loginctl enable-linger` it also starts at boot on a headless machine.
const unitName = "paxxmaker-connect.service"

func unitPath() string {
	d, _ := os.UserConfigDir()
	return filepath.Join(d, "systemd", "user", unitName)
}

func setLaunchAtLogin(on bool) error {
	if !on {
		_ = exec.Command("systemctl", "--user", "disable", unitName).Run()
		if err := os.Remove(unitPath()); err != nil && !os.IsNotExist(err) {
			return err
		}
		return exec.Command("systemctl", "--user", "daemon-reload").Run()
	}
	exe, err := os.Executable()
	if err != nil {
		return err
	}
	// --background: at login the program belongs in the background, not in the way.
	unit := fmt.Sprintf(`[Unit]
Description=%s (PaxxMaker app <-> OrcaSlicer bridge)
After=network-online.target

[Service]
ExecStart="%s" --background
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
`, appName, exe)
	if err := os.MkdirAll(filepath.Dir(unitPath()), 0o755); err != nil {
		return err
	}
	if b, err := os.ReadFile(unitPath()); err == nil && string(b) == unit {
		return nil
	}
	if err := os.WriteFile(unitPath(), []byte(unit), 0o644); err != nil {
		return err
	}
	_ = exec.Command("systemctl", "--user", "daemon-reload").Run()
	return exec.Command("systemctl", "--user", "enable", unitName).Run()
}

func launchAtLogin() bool { return fileExists(unitPath()) }
