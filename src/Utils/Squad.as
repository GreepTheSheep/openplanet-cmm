namespace Squad {
    Meta::PluginCoroutine@ squadFetchLoopCoroutine;

    void fetchSquadLoop() {
        while(g_activeSquad !is null) {
            sleep(1000);
            fetchSquadAsync(false);
        }
    }

    void fetchSquadAsync(const bool &in postLog = true) {
        Json::Value@ res = API::GetAsync(Setting_BaseURL+"/squad", postLog);

        if (res.GetType() == Json::Type::Null) {
            Log::Error("Error while loading squad");
            return;
        }

        if (res.HasKey("error")) {
            int errCode = res["error"]["code"];
            string errorMsg = res["error"]["message"];
            if (errCode == 404) {
                @g_activeSquad = null;
                return;
            }
            Log::Error(errorMsg);
            return;
        }

        @g_activeSquad = Squad(res["squad"]);
    }
}