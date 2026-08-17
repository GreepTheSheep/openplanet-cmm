#if CMM_ALLOW_CHANGE_SETTINGS || CMM_DEV_BUILD || SIG_DEVELOPER
[Setting name="Base URL" category="Advanced" onchange="onChangeSettingBaseURL"]
#endif
string Setting_BaseURL = "https://tm-communitymatchmaking-api.greep.fr";

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