bool isServerAlive = false;
bool isCheckingServer = true;
MainWindow@ yammMainWindow;
DevWindow@ yammDevWindow;
Player@ g_connectedPlayer;
array<MatchmakingType@> g_matchmakingTypes;
Squad@ g_activeSquad;
uint g_connectedPlayerCount;

void RenderMenu()
{
    if (!isServerAlive) {
        if (UI::MenuItem("\\$f00" + Icons::TimesCircle + " \\$zYAMM: Server Unavailable")) {
            startnew(Main);
        }
        UI::SetPreviousTooltip("Click to retry");
        return;
    }
    if (Auth::connectionError && !Auth::connectionInProgress) {
        if (UI::MenuItem("\\$f00" + Icons::TimesCircle + " \\$zYAMM: Connection Error")) {
            startnew(Main);
        }
        UI::SetPreviousTooltip("Click to retry");
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
    isServerAlive = CheckServer();
    if (!isServerAlive) return;
    Auth::Login();
    Matchmaking::getMatchmakingTypes();
    @yammMainWindow = MainWindow();
    @yammDevWindow = DevWindow();
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
    Log::Error("Force API Down Enabled.\nThe plugin will not load.", true);
    return false;
#else
    isCheckingServer = true;
    Json::Value@ res = API::GetAsync(Setting_BaseURL);
    isCheckingServer = false;

    if (res.GetType() == Json::Type::Null) {
        Log::Error("Server seems not responding.\nThe plugin will not load.", true);
    } else if (res.GetType() == Json::Type::Object) {
        g_connectedPlayerCount = res["connectedPlayers"];
        return true;
    }
    return false;
#endif
}

void CheckServerLoop() {
    while(true) {
        sleep(5 * 60 * 1000);
        isServerAlive = CheckServer();
    }
}