pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Notification daemon plus the shell's own toasts (WiFi, fingerprint, ...)
Singleton {
    id: root

    property bool dnd: false
    // { uid, key, title, body, icon, timeout (ms, 0 = stays), urgent, notification }
    property var toasts: []
    property int lastUid: 0

    function push(t) {
        const toast = Object.assign({ key: "", icon: "info", timeout: 5000, urgent: false, notification: null }, t);
        toast.uid = ++lastUid;
        toast.created = Date.now();
        let list = toasts.filter(x => !toast.key || x.key !== toast.key);
        list.push(toast);
        if (list.length > 4)
            list = list.slice(list.length - 4);
        toasts = list;
    }

    function remove(uid) {
        toasts = toasts.filter(t => t.uid !== uid);
    }

    function removeKey(key) {
        toasts = toasts.filter(t => t.key !== key);
    }

    // Timed out: the notification expires
    function expire(uid) {
        const t = toasts.find(x => x.uid === uid);
        if (t?.notification)
            t.notification.expire();
        remove(uid);
    }

    // Clicked: run the default action if there is one, then dismiss
    function activate(uid) {
        const t = toasts.find(x => x.uid === uid);
        const n = t?.notification;
        if (n) {
            const action = Array.from(n.actions).find(a => a.identifier === "default");
            if (action)
                action.invoke();
            else
                n.dismiss();
        }
        remove(uid);
    }

    function clear() {
        for (const t of toasts) {
            if (t.notification)
                t.notification.dismiss();
        }
        toasts = [];
    }

    NotificationServer {
        keepOnReload: false
        actionsSupported: true
        bodyMarkupSupported: false
        onNotification: n => {
            const critical = n.urgency === NotificationUrgency.Critical;
            if (root.dnd && !critical) {
                n.dismiss();
                return;
            }
            n.tracked = true;
            root.push({
                title: (n.summary || n.appName || "MESSAGE").toUpperCase(),
                body: n.body,
                icon: critical ? "alert" : "bell",
                urgent: critical,
                timeout: critical ? 0 : (n.expireTimeout > 0 ? n.expireTimeout * 1000 : 6000),
                notification: n
            });
        }
    }

    // While sudo, polkit or the lock screen waits for a finger
    // (fingerprint/fp-indicator.service writes these events)
    Process {
        command: ["sh", "-c", "[ -e /run/fp-indicator/events ] && exec tail -n0 -F /run/fp-indicator/events"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data === "start")
                    root.push({ key: "finger", title: "FINGER REQUESTED", body: "PLACE A FINGER ON THE SENSOR", icon: "finger", timeout: 0 });
                else if (data === "stop")
                    root.removeKey("finger");
            }
        }
    }
}
