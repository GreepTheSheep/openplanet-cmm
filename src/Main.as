bool isServerAlive = false;
bool isCheckingServer = true;
MainWindow@ yammMainWindow;
DevWindow@ yammDevWindow;
Player@ g_connectedPlayer;
array<MatchmakingType@> g_matchmakingTypes;
Squad@ g_activeSquad;
uint g_connectedPlayerCount;
int64 stampServerRetry = -1;

void RenderMenu()
{
    string serverRefreshSeconds = Time::FormatString(" (next retry in %Ss)", stampServerRetry - Time::Stamp);
    if (serverRefreshSeconds == "<invalid>") serverRefreshSeconds = "";
    if (!isServerAlive) {
        UI::MenuItem("\\$f00" + Icons::TimesCircle + " \\$zYAMM: Server Unavailable"+ serverRefreshSeconds);
        return;
    }
    if (Auth::connectionError && !Auth::connectionInProgress) {
        UI::MenuItem("\\$f00" + Icons::TimesCircle + " \\$zYAMM: Connection Error"+ serverRefreshSeconds);
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
    startnew(CheckServerLoop);
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
        return true;
    }
    return false;
#endif
}

void CheckServerLoop() {
    while(true) {
        bool alive = CheckServer();
        if (alive && !isServerAlive) {
            Auth::Login();
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