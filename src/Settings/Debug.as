#if CMM_DEV_BUILD || SIG_DEVELOPER
[SettingsTab name="Debug" icon="FileCodeO" order="10"]
void RenderDebugSettingsTab() {
    if (stampServerRetry - Time::Stamp >= 0) UI::TextDisabled(Icons::Refresh + " Next server health check in " + Time::FormatString("%Ss", stampServerRetry - Time::Stamp));
    else UI::TextDisabled(Icons::Refresh + " A server health check is performed every minute" + (!isServerAlive ? ", but it appears there is a major error in the data being returned" : "") + ".");

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