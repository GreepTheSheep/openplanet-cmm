namespace Auth
{
    int retriesNumber = 0;
    bool connected = false;
    bool connectionError = false;
    bool connectionInProgress = false;
    string AccountToken = "";

    void Login() {
        retriesNumber++;
        connectionInProgress = true;
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
                    connectionError = true;
                }
            } else if (errCode == 403) {
                Log::Error(errMsg, true);
                connectionError = true;
            }
        }

        bool srvConnected = serverRes["connected"];
        connectionInProgress = false;

        if (srvConnected) {
            string srvDisplayName = serverRes["displayName"];
            Log::Log("Connected! Display name: " + srvDisplayName, Meta::IsDeveloperMode());
            g_connectedPlayerCount++;
            connectionError = false;
            connected = true;
            checkPlayerAsync();
            checkSquadAsync();
        }
    }

    void checkPlayerAsync() {
        Json::Value@ playerJson = API::GetAsync(Setting_BaseURL + "/user/me");

        if (playerJson.GetType() == Json::Type::Null) {
            Log::Error("Error while loading player info");
            return;
        }

        if (playerJson.HasKey("error")) {
            int errCode = playerJson["error"]["code"];
            string errorMsg = playerJson["error"]["message"];
            Log::Error(errorMsg);
            return;
        }

        @g_connectedPlayer = Player(playerJson);
    }

    void checkSquadAsync() {
        Json::Value@ squadJson = API::GetAsync(Setting_BaseURL + "/squad");

        if (squadJson.GetType() == Json::Type::Null) {
            Log::Error("Error while loading squad info");
            return;
        }

        if (squadJson.HasKey("error")) {
            int errCode = squadJson["error"]["code"];
            string errorMsg = squadJson["error"]["message"];
            if (errCode == 404) return;
            Log::Error(errorMsg);
            return;
        }

        @g_activeSquad = Squad(squadJson["squad"]);
        if (Squad::squadFetchLoopCoroutine is null || !Squad::squadFetchLoopCoroutine.IsRunning()) @Squad::squadFetchLoopCoroutine = startnew(Squad::fetchSquadLoop);
    }

    void Logoff() {
        Json::Value@ serverJson = Json::Object();
        serverJson["token"] = AccountToken;

        Json::Value@ serverRes = API::Post(Setting_BaseURL + "/auth/logoff", Json::Write(serverJson));
    }
}