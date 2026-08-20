#if CMM_ALLOW_CHANGE_SETTINGS || CMM_DEV_BUILD || SIG_DEVELOPER
[Setting hidden]
#endif
string Setting_BaseURL = "https://tm-communitymatchmaking-api.greep.fr";

[Setting hidden]
uint Setting_LastSelectedMatchmakingIndex = 0;

#if CMM_ALLOW_CHANGE_SETTINGS || CMM_DEV_BUILD || SIG_DEVELOPER
[SettingsTab name="Advanced" icon="Wrench"]
void RenderAdvancedSettingsTab() {
    bool changed = false;
    uint64 typingStart;

    UI::AlignTextToFramePadding();
    Setting_BaseURL = UI::InputText("Base URL##BaseURLSettingBaseURLInputText", Setting_BaseURL, changed);
    UI::SameLine();
    UI::TextDisabled(Icons::InfoCircle);
    UI::SetPreviousTooltip("When you make the change, the plugin will log you out and log you back in at the new URL during the next health check.");

    if (UI::GreenButton("Set to Production")) {
        Setting_BaseURL = "https://tm-communitymatchmaking-api.greep.fr";
        onChangeSettingBaseURL();
    }
    UI::SameLine();
    if (UI::BlueButton("Set to Dev environment")) {
        Setting_BaseURL = "https://tm-communitymatchmaking-api-dev-mer6bu6x.greep.fr";
        onChangeSettingBaseURL();
    }
    UI::SameLine();
    if (UI::GrayButton("Set to Localhost")) {
        Setting_BaseURL = "http://localhost:3000";
        onChangeSettingBaseURL();
    }

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
    g_squadEnabled = false;
}