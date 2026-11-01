import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.services

// STATION: LOCKED. The lock screen as a Wayland session lock: the star chart
// of the wallpaper, a lock window with the clock and the password, and the
// desktop widgets in the right column. Hyprland only shows the desktop again
// after `locked` goes back to false.
//
//   qs ipc call lock lock        (what `station lock` and hypridle call)
//   qs ipc call lock isLocked
//
// The password goes through PAM's "login" stack, like hyprlock. The finger
// works at the same time when pam_fprintd is installed (fingerprint/setup.sh),
// with the small stack in lock/pam/fingerprint.
//
// If Quickshell ever dies while locked, Hyprland keeps the screen locked
// (allow_session_lock_restore): switch to a TTY and run
//   hyprctl --instance 0 dispatch exec hyprlock
Scope {
    id: root

    // What the lock window shows below the password field
    property string status: ""
    property bool statusIsError: false
    property bool busy: false
    property int attempts: 0
    // The typed password, shared by the lock windows on all screens
    property string buffer: ""
    property string pending: ""

    // Kept here: WlSessionLock doesn't signal when `locked` goes back to
    // false, so a binding to lock.locked would stay true after unlocking
    property bool locked: false
    property bool hasFinger: false
    readonly property bool fingerReady: hasFinger && finger.active

    function lockNow() {
        if (locked)
            return;
        status = "";
        statusIsError = false;
        buffer = "";
        attempts = 0;
        fingerTries = 0;
        locked = true;
        lock.locked = true;
        // Looked up on every lock, so the finger works right after
        // fingerprint/setup.sh without restarting Quickshell
        fingerCheck.running = true;
    }

    function unlock() {
        fingerStart.stop();
        if (pam.active)
            pam.abort();
        if (finger.active)
            finger.abort();
        buffer = "";
        pending = "";
        busy = false;
        locked = false;
        lock.locked = false;
    }

    function submit() {
        if (busy || buffer === "")
            return;
        pending = buffer;
        buffer = "";
        busy = true;
        status = "CHECKING ...";
        statusIsError = false;
        if (!pam.start()) {
            busy = false;
            pending = "";
            status = "PAM NOT AVAILABLE";
            statusIsError = true;
        }
    }

    WlSessionLock {
        id: lock

        LockSurface {
            ctl: root
        }
    }

    // Password
    PamContext {
        id: pam

        config: "login"

        onResponseRequiredChanged: {
            if (responseRequired)
                respond(root.pending);
        }

        onCompleted: result => {
            root.pending = "";
            root.busy = false;
            if (result === PamResult.Success) {
                root.unlock();
                return;
            }
            root.attempts++;
            root.statusIsError = true;
            // faillock and friends explain themselves ("account locked ...")
            root.status = messageIsError && message !== "" ? message.toUpperCase() : "ACCESS DENIED (" + root.attempts + ")";
        }

        onError: {
            root.pending = "";
            root.busy = false;
            root.statusIsError = true;
            root.status = "PAM ERROR";
        }
    }

    // Finger, next to the password. pam_fprintd gives up after a few tries or
    // 30 seconds; then it starts again, unless it keeps failing right away
    // (no sensor, no finger enrolled).
    property int fingerTries: 0
    property double fingerSince: 0

    Process {
        id: fingerCheck
        command: ["test", "-e", "/usr/lib/security/pam_fprintd.so"]
        onExited: code => {
            root.hasFinger = code === 0;
            if (root.hasFinger)
                fingerStart.restart();
        }
    }

    PamContext {
        id: finger

        configDirectory: Quickshell.shellDir + "/lock/pam"
        config: "fingerprint"

        onPamMessage: {
            if (/(fail|no match|not match)/i.test(message)) {
                root.status = "FINGER NOT RECOGNISED";
                root.statusIsError = true;
            }
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlock();
                return;
            }
            // Quick failures mean there is nothing to scan with
            root.fingerTries = Date.now() - root.fingerSince < 2000 ? root.fingerTries + 1 : 0;
            if (root.locked && root.fingerTries < 3)
                fingerStart.restart();
        }
    }

    Timer {
        id: fingerStart

        interval: 800
        onTriggered: {
            if (root.locked && root.hasFinger && !finger.active) {
                root.fingerSince = Date.now();
                finger.start();
            }
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lockNow();
        }

        function isLocked(): bool {
            return root.locked;
        }
    }
}
