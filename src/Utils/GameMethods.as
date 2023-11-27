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
}