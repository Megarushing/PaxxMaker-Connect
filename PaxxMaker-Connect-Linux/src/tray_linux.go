//go:build linux

package main

// The tray icon in the panel: open the pairing page, toggle start-at-login,
// quit. Without a desktop tray (headless, started by systemd) it just keeps
// serving.

import (
	_ "embed"
	"os"

	"fyne.io/systray"
)

func runTray() {
	systray.Run(func() {
		systray.SetIcon(trayIcon)
		systray.SetTitle(appName)
		systray.SetTooltip(appName + " – " + L("Bereit", "Ready"))
		show := systray.AddMenuItem(L("Kopplung anzeigen…", "Show pairing…"), "")
		systray.AddSeparator()
		auto := systray.AddMenuItemCheckbox(L("Beim Anmelden starten", "Start at login"), "", launchAtLogin())
		systray.AddSeparator()
		quit := systray.AddMenuItem(L("Beenden", "Quit"), "")
		go func() {
			for {
				select {
				case <-show.ClickedCh:
					showPairing()
				case <-auto.ClickedCh:
					on := !auto.Checked()
					if err := setLaunchAtLogin(on); err == nil {
						if on {
							auto.Check()
						} else {
							auto.Uncheck()
						}
					}
				case <-quit.ClickedCh:
					systray.Quit()
				}
			}
		}()
	}, func() { os.Exit(0) })
}

func quitApp() { systray.Quit() }

// Linux trays want a PNG, not the .ico.
//
//go:embed assets/icon.png
var trayIcon []byte
