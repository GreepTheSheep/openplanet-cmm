bool isServerAlive = false;
bool isCheckingServer = true;
MainWindow@ yammMainWindow;
DevWindow@ yammDevWindow;
Player@ g_connectedPlayer;
array<MatchmakingType@> g_matchmakingTypes;
Squad@ g_activeSquad;
MatchmakingType@ g_selectedMatchmakingType;
PlayerMatchmakingType@ g_selectedPlayerMatchmakingType;
uint g_connectedPlayerCount = 0;
uint g_queuePlayersCount = 0;
bool g_squadEnabled = false;
string g_serverInstanceId = "";
UserNotice@ g_userNotice;
int64 stampServerRetry = -1;
bool g_queueJoin = false;
bool g_inMatch = false;
bool g_connectedToMatchGameServer = false;
Match@ g_matchInfo;

UI::Font@ g_headerFont;

void RenderMenu()
{
    string serverRefreshSeconds = Time::FormatString(" (next retry in %Ss)", stampServerRetry - Time::Stamp);
    if (serverRefreshSeconds == "<invalid>") serverRefreshSeconds = "";
    if (Auth::connectionError && !Auth::connectionInProgress) {
        UI::MenuItem("\\$f00" + Icons::TimesCircle + " \\$zYAMM: Connection Error"+ serverRefreshSeconds);
        return;
    }
    if (!isServerAlive) {
        UI::MenuItem("\\$f00" + Icons::TimesCircle + " \\$zYAMM: Server Unavailable"+ serverRefreshSeconds);
        return;
    }
    if (isCheckingServer || !Auth::connected || Auth::connectionInProgress) return;
    if (Meta::IsDeveloperMode() && yammDevWindow !is null && UI::MenuItem("YAMM Superadmin Interface", "", yammDevWindow.isOpened)) {
        yammDevWindow.isOpened = !yammDevWindow.isOpened;
    }
    if (yammMainWindow !is null && UI::MenuItem(ICON_COL + PLUGIN_NAME, "", yammMainWindow.isOpened)) {
        yammMainWindow.isOpened = !yammMainWindow.isOpened;
    }
}


void Main()
{
    @g_headerFont = UI::LoadFont("DroidSans.ttf", 24, -1, -1, true, true, true);
    if (!TM::hasPermissions()) Log::Error("Missing permissions: you need to be able to play on public room to use this plugin.", true);
    else startnew(CheckServerLoop);
}

void OnDisabled() {
    if (Auth::connected) Auth::Logoff();
}
void OnDestroyed() {
    if (Auth::connected) Auth::Logoff();
}

void RenderInterface(){
    if (yammMainWindow !is null) yammMainWindow.Render();
    if (yammDevWindow !is null) yammDevWindow.Render();
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
        if (res.HasKey("squadEnabled")) g_squadEnabled = res["squadEnabled"];
        @g_userNotice = UserNotice(res["notice"]);

        // server instance Id will check if the server has been restarted between last check and this check
        // If the instance Id is not the same, then the server has been restarted, so the plugin had to redo the auth process
        // this is to prevent "Connected player not found" errors
        string instanceId = res["instanceId"];
        if (Meta::IsDeveloperMode()) Log::Trace("Server instance id: " + instanceId);
        if (g_serverInstanceId.Length == 0) g_serverInstanceId = instanceId;
        if (g_serverInstanceId != instanceId) {
            Log::Warn("Server instance ID is incorrect, this is due to server restarting. Logging out. Logging in will be done in a minute", true);
            g_serverInstanceId = instanceId;
            return false;
        }

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
            @yammMainWindow = MainWindow();
            @yammDevWindow = DevWindow();
        }
        if (isServerAlive && !alive) {
            @yammMainWindow = null;
            @yammDevWindow = null;
        }
        isServerAlive = alive;
        stampServerRetry = Time::Stamp + 60;
        sleep(1 * 60 * 1000);
    }
}

void PingMatchmakingLoop() {
    while (g_queueJoin || g_inMatch) {
        if (g_queueJoin) sleep(5000);
        else if (g_inMatch) sleep(20000);
        if (!g_queueJoin && !g_inMatch) return;

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
            Log::Error("Error while loading matchmaking");
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
    }
}