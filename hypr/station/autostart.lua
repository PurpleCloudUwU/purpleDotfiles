-- Started once when Hyprland starts (not on reload)

hl.on("hyprland.start", function()
    -- Quickshell: bar, program select, widgets, notifications, OSD
    hl.exec_cmd("qs")
    -- Idle: dim, lock, screen off, suspend on battery (hypridle.conf)
    hl.exec_cmd("hypridle")
    -- Password and fingerprint dialogs for apps that need root
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    -- Dark GTK and libadwaita apps
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark")
end)
