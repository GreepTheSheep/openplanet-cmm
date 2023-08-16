bool isServerAlive = false;
bool isCheckingServer = true;
MainWindow@ yammMainWindow;
DevWindow@ yammDevWindow;
uint g_connectedPlayers;

void RenderMenu()
{
    if (isCheckingServer || !isServerAlive || !Auth::connected) return;
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
    @yammMainWindow = MainWindow();
    @yammDevWindow = DevWindow();
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
    if (yammMainWindow !is null) yammMainWindow.Render();
    if (yammDevWindow !is null) yammDevWindow.Render();
}

void Render()
{
    Renderables::Render();
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