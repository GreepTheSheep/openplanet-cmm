bool isServerAlive = false;
bool isCheckingServer = true;
MainWindow@ bmmMainWindow;
DevWindow@ bmmDevWindow;
uint g_connectedPlayers;

void RenderMenu()
{
    if (isCheckingServer || !isServerAlive || !Auth::connected) return;
    if (Meta::IsDeveloperMode() && bmmDevWindow !is null && UI::MenuItem("TMBMM Superadmin Interface", "", bmmDevWindow.isOpened)) {
        bmmDevWindow.isOpened = !bmmDevWindow.isOpened;
    }
    if (bmmMainWindow !is null && UI::MenuItem(ICON_COL + PLUGIN_NAME, "", bmmMainWindow.isOpened)) {
        bmmMainWindow.isOpened = !bmmMainWindow.isOpened;
    }
}


void Main()
{
    isServerAlive = CheckServer();
    if (!isServerAlive) return;
    Auth::Login();
    @bmmMainWindow = MainWindow();
    @bmmDevWindow = DevWindow();
    startnew(CheckServerLoop);
    print("ready");
}

void OnDisabled() {
    if (Auth::connected) Auth::Logoff();
}
void OnDestroyed() {
    if (Auth::connected) Auth::Logoff();
}

void RenderInterface(){
    if (bmmMainWindow !is null) bmmMainWindow.Render();
    if (bmmDevWindow !is null) bmmDevWindow.Render();
}

bool CheckServer()
{
    isCheckingServer = true;
    Json::Value@ res = API::GetAsync(Setting_BaseURL);
    isCheckingServer = false;

    if (res.GetType() == Json::Type::Null) {
        Log::Error("Server seems not responding.\nThe plugin will not load.");
        throw("Server seems not responding");
    } else if (res.GetType() == Json::Type::Object) {
        g_connectedPlayers = res["connectedPlayers"];
        return true;
    }
    return false;
}

void CheckServerLoop() {
    while(true) {
        sleep(5 * 60 * 1000);
        isServerAlive = CheckServer();
    }
}