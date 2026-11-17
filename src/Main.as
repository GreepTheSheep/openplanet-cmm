bool isServerAlive = false;
bool isCheckingServer = true;
MainWindow@ cmmMainWindow;
DevWindow@ cmmDevWindow;
Player@ g_connectedPlayer;
array<MatchmakingType@> g_matchmakingTypes;
Squad@ g_activeSquad;
MatchmakingType@ g_selectedMatchmakingType;
PlayerMatchmakingType@ g_selectedPlayerMatchmakingType;
ServerInfo@ g_serverInfo;
uint g_queuePlayersCount = 0;
UserNotice@ g_userNotice;
int64 stampServerRetry = -1;
bool g_queueJoin = false;
uint64 g_queueJoinTime;
bool g_inMatch = false;
bool g_isPingingMatchmakingQueue = false;
uint64 g_lastPingQueue;
uint64 g_lastPingQueueSent;
bool g_connectedToMatchGameServer = false;
Match@ g_matchInfo;
TcpSocketClient@ g_tcpSocket;

void RenderMenu()
{
    if (!TM::hasPermissions()) return;
    string serverRefreshSeconds;
    if (stampServerRetry - Time::Stamp >= 0) serverRefreshSeconds = Time::FormatString(Icons::Refresh + " %Ss", stampServerRetry - Time::Stamp);
    if (serverRefreshSeconds == "<invalid>") serverRefreshSeconds = "";

    if (Auth::connectionError && !Auth::connectionInProgress) {
        UI::MenuItem("\\$f00" + Icons::TimesCircle + "\\$z "+PLUGIN_NAME_SHORT+": Connection Error", serverRefreshSeconds);
        return;
    }
    if (isCheckingServer) {
        UI::MenuItem(PLUGIN_ICON + " " + PLUGIN_NAME_SHORT+": Checking services...");
        return;
    }
    if (Auth::connectionInProgress) {
        UI::MenuItem(Icons::Server + " " + PLUGIN_NAME_SHORT+": Authenticating...");
        return;
    }
    if (!isServerAlive) {
        UI::MenuItem("\\$f00" + Icons::TimesCircle + "\\$z "+PLUGIN_NAME_SHORT+": Server Unavailable", serverRefreshSeconds);
        return;
    }
    if (!Auth::connected) {
        // Menu Item to remove when beta test is done
        if (UI::MenuItem(ICON_COL + PLUGIN_NAME_SHORT + ": Register to beta test", Icons::ExternalLink)) {
            OpenBrowserURL("https://forms.gle/xFo3XBK3DTNHyqv6A");
        }
        return;
    };
    if (cmmMainWindow !is null && UI::MenuItem(ICON_COL + PLUGIN_NAME, "", cmmMainWindow.isOpened)) {
        cmmMainWindow.isOpened = !cmmMainWindow.isOpened;
    }
    if (cmmDevWindow !is null && g_connectedPlayer !is null && g_connectedPlayer.canHaveAdminWindow() && UI::MenuItem(PLUGIN_NAME_SHORT+" Admin Interface", "", cmmDevWindow.isOpened)) {
        cmmDevWindow.isOpened = !cmmDevWindow.isOpened;
    }
}


void Main()
{
    if (!TM::hasPermissions()) {
        Log::Error("Missing permissions: you need to be able to play on public room to use this plugin.", true);
        return;
    }
    startnew(Fonts::Load);
    startnew(CheckServerLoop);
}

void OnDisabled() {
    if (Auth::connected) {
        g_tcpSocket.disconnect();
        Auth::Logoff();
    }
}
void OnDestroyed() {
    if (Auth::connected) {
        g_tcpSocket.disconnect();
        Auth::Logoff();
    }
}

void RenderInterface(){
    if (cmmMainWindow !is null) cmmMainWindow.Render();
    if (cmmDevWindow !is null) cmmDevWindow.Render();
}

void Render()
{
    Renderables::Render();
}

bool CheckServer()
{
    isCheckingServer = true;
    Json::Value@ res = API::GetAsync(Setting_BaseURL, false);
    isCheckingServer = false;

    if (res.GetType() == Json::Type::Null) {
        if (!isServerAlive) Log::Error("Server is not responding.", false);
    } else if (res.GetType() == Json::Type::Object) {
        @g_serverInfo = ServerInfo(res);
        @g_userNotice = UserNotice(res["notice"]);

        return true;
    }
    return false;
}

void CheckServerLoop() {
    if (Auth::connectionError) return;
    while(true) {
        yield();
        bool alive = CheckServer();
        if (alive && !isServerAlive) {
            isServerAlive = true;
            Auth::Login();
            if (Auth::connectionError) return;
            Matchmaking::getMatchmakingTypes();
            @cmmMainWindow = MainWindow();
            @cmmDevWindow = DevWindow();
        }
        if (isServerAlive && !alive) {
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
        stampServerRetry = Time::Stamp + 60;
        sleep(1 * 60 * 1000);
    }
}

void PingMatchmakingLoop() {
    while (g_queueJoin || g_inMatch) {
        g_isPingingMatchmakingQueue = false;
        if (!g_queueJoin && !g_inMatch) return;

        if (g_queueJoin) sleep(5000);
        else if (g_inMatch) sleep(20000);

        g_isPingingMatchmakingQueue = true;
        g_lastPingQueueSent = Time::Now;

        dictionary params;
        params.Set("matchmakingId", tostring(g_selectedMatchmakingType.id));

        string urlParams = "";
        if (!params.IsEmpty()) {
            auto keys = params.GetKeys();
            for (uint i = 0; i < keys.Length; i++) {
                string key = keys[i];
                string value;
                params.Get(key, value);

                urlParams += (i == 0 ? "?" : "&");
                urlParams += key + "=" + Net::UrlEncode(value);
            }
        }

        Json::Value@ res = API::GetAsync(Setting_BaseURL+"/matchmaking/ping" + urlParams, false);

        if (res.GetType() == Json::Type::Null) {
            Log::Error("Error while pinging matchmaking");
            return;
        }

        if (res.HasKey("error")) {
            string errorMsg = res["error"]["message"];
            Log::Error(errorMsg);
            return;
        }

        g_queueJoin = res["inQueue"];
        if (res.HasKey("queueLength")) g_queuePlayersCount = res["queueLength"];
        else g_queuePlayersCount = 0;

        g_lastPingQueue = Time::Now;

        // Update squad state from ping response
        if (res.HasKey("squad") && res["squad"].GetType() == Json::Type::Object) {
            if (g_activeSquad !is null) {
                Squad::applySquadExtras(g_activeSquad, res["squad"]);
                if (!g_queueJoin && !g_inMatch) {
                    g_activeSquad.isSearching = false;
                }
                Squad::SyncSquadMatchmakingType(g_activeSquad.matchmakingTypeId);
            }
        } else if (res.HasKey("squad") && res["squad"].GetType() == Json::Type::Null) {
            @g_activeSquad = null;
            @Squad::squadFetchLoopCoroutine = null;
        }

        if (res["match"].GetType() == Json::Type::Object) {
            @g_matchInfo = Match(res["match"]);
            if (!g_tcpSocket.connected) { // All data will be handled by the TCP socket at this point, only if the socket is connected
                g_inMatch = true;
                if (g_matchInfo.tmServer !is null && g_matchInfo.tmServer.quickJoinLink != "") {
                    if (!g_connectedToMatchGameServer && g_matchInfo.status.ToLower().StartsWith("waiting for players")) {
                        TM::JoinServer(g_matchInfo.tmServer.quickJoinLink);
                        g_connectedToMatchGameServer = true;
                    }
                }
            }
            for (uint t = 0; t < g_matchInfo.teams.Length; t++) {
                for (uint tp = 0; tp < g_matchInfo.teams[t].players.Length; tp++) {
                    // For each players in the match, fetch their badges
                    // (safeguard with their private propriety NextFetchBadgesTimestamp)
                    g_matchInfo.teams[t].players[tp].fetchBadgesAsync();
                }
            }
        } else if (res["match"].GetType() == Json::Type::Null) {
            if (g_inMatch == true) {
                // Refresh player points after the match
                @g_connectedPlayer = Player(API::GetAsync(Setting_BaseURL+"/user/me"));

                for (uint p = 0; p < g_connectedPlayer.matchmakingTypes.Length; p++) {
                    if (g_connectedPlayer.matchmakingTypes[p].matchmakingTypeId == g_selectedMatchmakingType.id) {
                        @g_selectedPlayerMatchmakingType = g_connectedPlayer.matchmakingTypes[p];
                        break;
                    }
                }
            }
            g_inMatch = false;
            g_connectedToMatchGameServer = false;
            @g_matchInfo = null;
        }
        g_isPingingMatchmakingQueue = false;
    }
}