#if CMM_ALLOW_CHANGE_SETTINGS || CMM_DEV_BUILD || SIG_DEVELOPER
[Setting hidden]
#endif
string Setting_BaseURL = URL_PROD;

#if CMM_ALLOW_CHANGE_SETTINGS || CMM_DEV_BUILD || SIG_DEVELOPER
[SettingsTab name="Advanced" icon="Wrench" order="1"]
void RenderAdvancedSettingsTab() {
    bool changed = false;
    uint64 typingStart;

    UI::AlignTextToFramePadding();
    Setting_BaseURL = UI::InputText("Base URL##BaseURLSettingBaseURLInputText", Setting_BaseURL, changed);
    UI::SameLine();
    UI::TextDisabled(Icons::InfoCircle);
    UI::SetItemTooltip("When you make the change, the plugin will log you out and log you back in at the new URL during the next health check.");

    UI::BeginDisabled(Setting_BaseURL == URL_PROD);
    if (UI::GreenButton("Set to Production")) {
        Setting_BaseURL = URL_PROD;
        onChangeSettingBaseURL();
    }
    UI::EndDisabled();
    UI::SameLine();
    UI::BeginDisabled(Setting_BaseURL == URL_STAGING);
    if (UI::BlueButton("Set to Staging")) {
        Setting_BaseURL = URL_STAGING;
        onChangeSettingBaseURL();
    }
    UI::EndDisabled();
    UI::SameLine();
    UI::BeginDisabled(Setting_BaseURL == URL_LOCALHOST);
    if (UI::GrayButton("Set to Localhost")) {
        Setting_BaseURL = URL_LOCALHOST;
        onChangeSettingBaseURL();
    }
    UI::EndDisabled();

    if (changed) typingStart = Time::Now;

    if (typingStart == 0) return;

    if (Time::Now > typingStart + 1000) {
        typingStart = 0;
        onChangeSettingBaseURL();
    }
}
#endif

void onChangeSettingBaseURL() {
    // Marks the plugin to be disconnected from the server, so it'll do the auth process on the next check sweep
    isServerAlive = false;
    @cmmMainWindow = null;
    @cmmDevWindow = null;
    g_matchmakingTypes.RemoveRange(0, g_matchmakingTypes.Length);
    g_queueJoin = false;
    g_inMatch = false;
    @g_matchInfo = null;
    g_connectedToMatchGameServer = false;
    @g_activeSquad = null;
    @g_serverInfo = null;
    if (g_tcpSocket !is null) {
        g_tcpSocket.disconnect();
        @g_tcpSocket = null;
    }
}