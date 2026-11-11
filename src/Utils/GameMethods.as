namespace TM {

    bool hasPermissions() {
        return Permissions::PlayPublicClubRoom();
    }

    void JoinServer(const string &in joinLink) {
        if (!hasPermissions()) return;
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        app.ManiaPlanetScriptAPI.OpenLink(joinLink, CGameManiaPlanetScriptAPI::ELinkType::ManialinkBrowser);
        g_connectedToMatchGameServer = true;
    }

    void FlashWindow() {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        app.ManiaPlanetScriptAPI.FlashWindow();
    }

    void CreateLocalServer(const string &in serverName, const string &in mapFileName, const string &in scriptModeName = "Modes/TrackMania/FlagRush.Script.txt", const string &in scriptModeSettingsXml = "") {
        if (!Permissions::CreateLocalServer()) {
            Log::Error("You don't have permissions to create a local server.", true);
            return;
        }
        CTrackMania@ app = cast<CTrackMania>(GetApp());

        // Create a buffer of the single map
        auto mapBuffer = MwFastBuffer<wstring>();
        mapBuffer.Add(mapFileName);

        app.ManiaTitleControlScriptAPI.CreateServer3(serverName, "", 16, "", "", false, mapBuffer, scriptModeName, "<playlist><mode_script_settings>"+scriptModeSettingsXml+"</mode_script_settings></playlist>");
    }
}