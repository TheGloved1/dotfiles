import QtQuick
import Quickshell
import Quickshell.Ipc
import qs.Modules.Plugins
PluginComponent {
    id: root
    IpcHandler {
        target: "mytestplugin"
        enabled: true
        function ping() { return "pong" }
    }
}
