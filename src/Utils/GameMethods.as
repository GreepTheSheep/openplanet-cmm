namespace TM {

    bool hasPermissions() {
        return Permissions::PlayPublicClubRoom();
    }

    void JoinServer(const string &in joinLink) {
        if (!hasPermissions()) return;
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        app.ManiaPlanetScriptAPI.OpenLink(joinLink, CGameManiaPlanetScriptAPI::ELinkType::ManialinkBrowser);
    }

    void FlashWindow() {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        app.ManiaPlanetScriptAPI.FlashWindow();
    }

    void CreateLocalServer(const string &in serverName, const string &in mapFileName, const string &in scriptModeName = "Modes/TrackMania/TM_TimeAttack_Online.Script.txt", const string &in scriptModeSettingsXml = "<setting name=\"S_TimeLimit\" type=\"integer\" value=\"0\"/>") {
        if (!Permissions::CreateLocalServer()) {
            Log::Error("You don't have permissions to create a local server.", true);
            return;
        }
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        app.BackToMainMenu();
        while (!app.ManiaTitleControlScriptAPI.IsReady) yield();

        // Create a buffer of the single map
        auto mapBuffer = MwFastBuffer<wstring>();
        mapBuffer.Add(mapFileName);

        app.ManiaTitleControlScriptAPI.CreateServer3(
            serverName, // Name
            "", // Server comment
            16, // Max players
            "", // Password
            "", // Password for spectators
            false, // Local only
            mapBuffer, // Maps
            scriptModeName, // Script file
            "<playlist><mode_script_settings>"+scriptModeSettingsXml+"</mode_script_settings></playlist>" // Script settings XML format
        );
    }
}