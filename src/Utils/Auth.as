namespace Auth
{
    int retriesNumber = 0;
    bool connected = false;
    string AccountToken = "";

    void Login() {
        retriesNumber++;
        Log::Log("Starting Auth...");

        Auth::PluginAuthTask@ tokenTask = Auth::GetToken();

        while (!tokenTask.Finished()) yield();

        AccountToken = tokenTask.Token();

        if (Meta::IsDeveloperMode()) Log::Trace("Token: " + AccountToken);
        if (Meta::IsDeveloperMode()) Log::Log("Sending Token...");

        CTrackManiaNetwork@ Network = cast<CTrackManiaNetwork>(GetApp().Network);
        string displayName = Network.PlayerInfo.Name;
        string accountId = Network.PlayerInfo.WebServicesUserId;

        Json::Value@ serverJson = Json::Object();
        serverJson["token"] = AccountToken;
        serverJson["displayName"] = displayName;
        serverJson["accountId"] = accountId;
        serverJson["pluginVersion"] = Meta::ExecutingPlugin().Version;

        Json::Value@ serverRes = API::PostAsync(Setting_BaseURL + "/auth/login", Json::Write(serverJson));

        if (serverRes.HasKey("error")) {
            string errMsg = serverRes["error"]["message"];
            int errCode = serverRes["error"]["code"];
            if (errCode == 502) {
                if (retriesNumber <= 3) {
                    Log::Warn(errMsg + "\nRetrying... ("+retriesNumber+"/3 attempts)");
                    sleep(2000);
                    Auth::Login();
                } else {
                    Log::Error(errMsg + "\nThe plugin will not load.");
                    throw(errMsg);
                }
            } else if (errCode == 403) {
                Log::Error(errMsg, true);
                throw(errMsg);
            }
        }

        bool srvConnected = serverRes["connected"];

        if (srvConnected) {
            string srvDisplayName = serverRes["displayName"];
            Log::Log("Connected! Display name: " + srvDisplayName, Meta::IsDeveloperMode());
            g_connectedPlayers++;
            connected = true;
        }
    }

    void Logoff() {
        Json::Value@ serverJson = Json::Object();
        serverJson["token"] = AccountToken;

        Json::Value@ serverRes = API::Post(Setting_BaseURL + "/auth/logoff", Json::Write(serverJson));
    }
}