#!/usr/bin/env bash
# Fingerprint login for the ThinkPad T580 (Synaptics 06cb:009a), not part of
# install.sh because it only fits this sensor. Run as your normal user:
#   ~/purpleDotfiles/fingerprint/setup.sh
#
# - python-validity + open-fprintd drive the sensor, libfprint can't
# - sudo and polkit dialogs accept the finger (password still works: Ctrl+C
#   in the terminal, or just type it in the dialog)
# - fp-indicator.service tells Quickshell when a finger is wanted, which then
#   shows a "FINGER REQUESTED" notification
set -euo pipefail

dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
info() { printf '\n\033[1;35m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
((EUID != 0)) || { echo "run this as your normal user, not as root" >&2; exit 1; }

# python-validity from the AUR doesn't start on this sensor with Python 3.14
# (uunicorn/python-validity#272), so build it with the fixes from PR #290
info "Installing python-validity with the 06cb:009a fixes"
if ! pacman -Q python-validity-patched >/dev/null 2>&1; then
    helper=$(command -v paru || command -v yay)
    "$helper" -S --needed --asdeps open-fprintd fprintd-clients
    (cd "$dir/python-validity-patched" && makepkg -si --needed)
fi

info "Keeping the sensor awake and its firmware across reboots"
sudo install -Dm644 "$dir/99-fingerprint-power.rules" /etc/udev/rules.d/99-fingerprint-power.rules
sudo udevadm control --reload
sudo udevadm trigger --action=add --attr-match=idVendor=06cb --attr-match=idProduct=009a
# TLP would put it back to autosuspend
if ! grep -qs 'USB_DENYLIST=.*06cb:009a' /etc/tlp.d/*.conf; then
    echo 'USB_DENYLIST="06cb:009a"   # fingerprint sensor hangs in autosuspend' |
        sudo tee /etc/tlp.d/95-fingerprint.conf >/dev/null
fi
sudo systemctl stop python3-validity.service open-fprintd.service 2>/dev/null || true
sudo install -Dm644 "$dir/python-validity.conf" /etc/tmpfiles.d/python-validity.conf
sudo systemd-tmpfiles --create /etc/tmpfiles.d/python-validity.conf
[[ -n $(ls /var/lib/python-validity/*.xpfwext 2>/dev/null) ]] || sudo validity-sensors-firmware

info "Enabling the sensor services"
# open-fprintd itself is static (started over D-Bus), so it is not in the list
for s in python3-validity open-fprintd-resume open-fprintd-suspend; do
    systemctl cat "$s.service" >/dev/null 2>&1 && sudo systemctl enable "$s.service"
done
sudo systemctl restart python3-validity.service open-fprintd.service

info "Installing the indicator service"
sudo install -Dm755 "$dir/fp-indicator-monitor" /usr/local/bin/fp-indicator-monitor
sudo install -Dm644 "$dir/fp-indicator.service" /etc/systemd/system/fp-indicator.service
sudo systemctl daemon-reload
sudo systemctl enable --now fp-indicator.service

info "PAM: finger for sudo and polkit"
line='auth       sufficient   pam_fprintd.so'
# polkit only ships /usr/lib/pam.d/polkit-1; a copy in /etc/pam.d overrides it
[[ -f /etc/pam.d/polkit-1 ]] || sudo cp /usr/lib/pam.d/polkit-1 /etc/pam.d/polkit-1
for f in /etc/pam.d/sudo /etc/pam.d/polkit-1; do
    grep -q pam_fprintd "$f" || sudo sed -i "1a $line" "$f"
done

info "Enrolling a finger (swipe it a few times when asked)"
if ! fprintd-enroll; then
    echo "Enrolling failed. A factory reset of the sensor usually helps:"
    echo "  sudo python3 /usr/share/python-validity/playground/factory-reset.py"
    echo "  sudo systemctl restart python3-validity open-fprintd"
    echo "then run: fprintd-enroll"
    exit 1
fi
fprintd-verify
info "Done, try it: sudo -k; sudo true"
