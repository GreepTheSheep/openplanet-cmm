bool isServerAlive = false;
bool isCheckingServer = true;
MainWindow@ cmmMainWindow;
DevWindow@ cmmDevWindow;
Player@ g_connectedPlayer;
array<MatchmakingType@> g_matchmakingTypes;
Squad@ g_activeSquad;
MatchmakingType@ g_selectedMatchmakingType;
PlayerMatchmakingType@ g_selectedPlayerMatchmakingType;
uint g_connectedPlayerCount = 0;
int g_lastSquadMatchmakingTypeId = -1;
uint g_queuePlayersCount = 0;
bool g_squadEnabled = false;
int64 g_clusterBootTimestamp;
int64 g_podBootTimestamp;
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

void RenderMenu()
{
    string serverRefreshSeconds;
    if (stampServerRetry - Time::Stamp >= 0) serverRefreshSeconds = Time::FormatString(Icons::Refresh + " %Ss", stampServerRetry - Time::Stamp);
    if (serverRefreshSeconds == "<invalid>") serverRefreshSeconds = "";

    if (Auth::connectionError && !Auth::connectionInProgress) {
        UI::MenuItem("\\$f00" + Icons::TimesCircle + "\\$z "+PLUGIN_NAME_SHORT+": Connection Error", serverRefreshSeconds);
        return;
    }
    if (!isServerAlive) {
        UI::MenuItem("\\$f00" + Icons::TimesCircle + "\\$z "+PLUGIN_NAME_SHORT+": Server Unavailable", serverRefreshSeconds);
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
    if (!Auth::connected) return;
    if (cmmDevWindow !is null && g_connectedPlayer !is null && g_connectedPlayer.canHaveAdminWindow() && UI::MenuItem(PLUGIN_NAME_SHORT+" Admin Interface", "", cmmDevWindow.isOpened)) {
        cmmDevWindow.isOpened = !cmmDevWindow.isOpened;
    }
    if (cmmMainWindow !is null && UI::MenuItem(ICON_COL + PLUGIN_NAME, "", cmmMainWindow.isOpened)) {
        cmmMainWindow.isOpened = !cmmMainWindow.isOpened;
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
    if (Auth::connected) Auth::Logoff();
}
void OnDestroyed() {
    if (Auth::connected) Auth::Logoff();
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
#if FORCE_API_DOWN
    Log::Error("Force API Down Enabled.");
    return !isServerAlive;
#else
    isCheckingServer = true;
    Json::Value@ res = API::GetAsync(Setting_BaseURL, false);
    isCheckingServer = false;

    if (res.GetType() == Json::Type::Null) {
        if (!isServerAlive) Log::Error("Server is not responding.", false);
    } else if (res.GetType() == Json::Type::Object) {
        g_connectedPlayerCount = res["connectedPlayers"];
        @g_userNotice = UserNotice(res["notice"]);
        g_clusterBootTimestamp = res["globalStartTimestamp"];
        g_podBootTimestamp = res["startTimestamp"];

        return true;
    }
    return false;
#endif
}

void CheckServerLoop() {
    if (Auth::connectionError) return;
    while(true) {
        bool alive = CheckServer();
        if (alive && !isServerAlive) {
            Auth::Login();
            if (Auth::connectionError) return;
            Matchmaking::getMatchmakingTypes();
            @cmmMainWindow = MainWindow();
            @cmmDevWindow = DevWindow();
        }
        if (isServerAlive && !alive) {
            @cmmMainWindow = null;
            @cmmDevWindow = null;
            g_matchmakingTypes.RemoveRange(0, g_matchmakingTypes.Length);
            g_queueJoin = false;
            g_inMatch = false;
            @g_matchInfo = null;
            g_connectedToMatchGameServer = false;
            g_squadEnabled = false;
        }
        isServerAlive = alive;
        stampServerRetry = Time::Stamp + 60;
        sleep(1 * 60 * 1000);
    }
}

void SyncSquadMatchmakingType(int squadTypeId) {
    if (squadTypeId <= 0) return;
    if (g_selectedMatchmakingType !is null && g_selectedMatchmakingType.id == squadTypeId) return;
    if (g_activeSquad is null) return;
    if (g_connectedPlayer.accountId == g_activeSquad.ownerPlayer) return; // sync for other players only, the owner (host) manages it
    for (uint i = 0; i < g_matchmakingTypes.Length; i++) {
        if (g_matchmakingTypes[i].id == squadTypeId) {
            @g_selectedMatchmakingType = g_matchmakingTypes[i];
            g_squadEnabled = g_selectedMatchmakingType.allowSquad;
            for (uint p = 0; p < g_connectedPlayer.matchmakingTypes.Length; p++) {
                if (g_connectedPlayer.matchmakingTypes[p].matchmakingTypeId == g_selectedMatchmakingType.id) {
                    @g_selectedPlayerMatchmakingType = g_connectedPlayer.matchmakingTypes[p];
                    break;
                }
            }
            return;
        }
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
                if (g_activeSquad.matchmakingTypeId != g_lastSquadMatchmakingTypeId) {
                    g_lastSquadMatchmakingTypeId = g_activeSquad.matchmakingTypeId;
                    SyncSquadMatchmakingType(g_activeSquad.matchmakingTypeId);
                }
            }
        } else if (res.HasKey("squad") && res["squad"].GetType() == Json::Type::Null) {
            @g_activeSquad = null;
            @Squad::squadFetchLoopCoroutine = null;
        }

        if (res["match"].GetType() == Json::Type::Object) {
            g_inMatch = true;
            @g_matchInfo = Match(res["match"]);
            if (g_matchInfo.tmServer !is null && g_matchInfo.tmServer.quickJoinLink != "") {
                if (!g_connectedToMatchGameServer && g_matchInfo.status.ToLower().StartsWith("waiting for players")) {
                    TM::JoinServer(g_matchInfo.tmServer.quickJoinLink);
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