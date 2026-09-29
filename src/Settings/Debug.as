#if CMM_DEV_BUILD || SIG_DEVELOPER
string socketDataToSend;

[SettingsTab name="Debug" icon="FileCodeO" order="2"]
void RenderDebugSettingsTab() {
    if (stampServerRetry - Time::Stamp >= 0) UI::TextDisabled(Icons::Refresh + " Next server health check in " + Time::FormatString("%Ss", stampServerRetry - Time::Stamp));
    else UI::TextDisabled(Icons::Refresh + " A server health check is performed every minute" + (!isServerAlive ? ", but it appears there is a major error in the data being returned" : "") + ".");

    if (UI::TreeNode("Socket", UI::TreeNodeFlags::Framed)) {
        if (g_tcpSocket !is null) {
            if (g_tcpSocket.connected) UI::TextWrapped(Icons::ArrowsH + " Connected to Socket. The plugin can receive updates from the server without polling.");
            else UI::Text(Icons::LongArrowRight  + " Not connected to Socket.");
            UI::NewLine();

            if (g_tcpSocket.socket !is null && g_tcpSocket.socket.IsReady()) {
                UI::TextDisabled(g_tcpSocket.host+":"+g_tcpSocket.port + " | " + g_tcpSocket.socket.GetRemoteIP());

                UI::TextWrapped(Icons::Kenney::Upload + " " + g_tcpSocket.lastWrite);
                if (UI::IsItemClicked()) IO::SetClipboard(g_tcpSocket.lastWrite);

                UI::TextWrapped(Icons::Kenney::Download + " " + g_tcpSocket.lastRead);
                if (UI::IsItemClicked()) IO::SetClipboard(g_tcpSocket.lastRead);

                socketDataToSend = UI::InputText("Data to send", socketDataToSend);
                if (UI::Button("Send")) {
                    g_tcpSocket.send(socketDataToSend);
                    socketDataToSend = "";
                }
            }
        } else UI::Text("Socket class is not initialized at the moment");
#if CMM_DISALLOW_SOCKETS
        UI::Text(Icons::TimesCircleO + " Sockets are disabled by the CMM_DISALLOW_SOCKETS define.");
#endif
        UI::TreePop();
    }

    if (UI::TreeNode("Main Window", UI::TreeNodeFlags::Framed)) {
        if (cmmMainWindow !is null) {
            UI::Text("Window Opened: " + (cmmMainWindow.isOpened ? Icons::Check : Icons::Times));
            UI::Text("Is Loading: " + (cmmMainWindow.isLoading ? Icons::Refresh : ""));
            if (cmmMainWindow.c_lastActiveTab !is null) UI::Text("Active tab: " + cmmMainWindow.c_lastActiveTab.GetID());
            else UI::Text("No active tab");
        } else UI::Text("Main Window is not initialized");
        UI::TreePop();
    }
}
#endif