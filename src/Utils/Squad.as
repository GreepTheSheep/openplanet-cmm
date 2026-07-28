namespace Squad {
    awaitable@ squadFetchLoopCoroutine;

    void fetchSquadLoop() {
        while(g_activeSquad !is null) {
            sleep(1000);
            fetchSquadAsync(false);
        }
    }

    void applySquadExtras(Squad@ squad, const Json::Value &in res) {
        if (squad is null) return;
        if (res.HasKey("readyStates")) {
            squad.readyStates = dictionary();
            auto keys = res["readyStates"].GetKeys();
            for (uint i = 0; i < keys.Length; i++) {
                squad.readyStates.Set(keys[i], bool(res["readyStates"][keys[i]]));
            }
        }
        if (res.HasKey("matchmakingTypeId")) {
            if (res["matchmakingTypeId"].GetType() == Json::Type::Null) squad.matchmakingTypeId = -1;
            else squad.matchmakingTypeId = int(res["matchmakingTypeId"]);
        }
        if (res.HasKey("isSearching")) {
            squad.isSearching = bool(res["isSearching"]);
        }
    }

    void handleSearchStateChanged() {
        if (g_activeSquad is null) return;
        if (g_activeSquad.isSearching) {
            if (!g_queueJoin && !g_inMatch) {
                g_queueJoin = true;
                g_queueJoinTime = Time::Now;
                startnew(PingMatchmakingLoop);
            }
        } else {
            if (g_queueJoin && !g_inMatch) {
                g_queueJoin = false;
            }
        }
    }

    void setMatchmakingType() {
        if (g_selectedMatchmakingType is null) return;
        Json::Value@ postJson = Json::Object();
        postJson["matchmakingId"] = g_selectedMatchmakingType.id;
        Json::Value@ res = API::PostAsync(Setting_BaseURL+"/squad/matchmaking", Json::Write(postJson));

        if (res.GetType() == Json::Type::Null) {
            Log::Error("Error while setting matchmaking type");
            if (g_activeSquad !is null) g_activeSquad.matchmakingTypeId = -1;
            return;
        }
        if (res.HasKey("error")) {
            Log::Error(res["error"]["message"]);
            if (g_activeSquad !is null) g_activeSquad.matchmakingTypeId = -1;
            return;
        }
        @g_activeSquad = Squad(res["squad"]);
        applySquadExtras(g_activeSquad, res);
        handleSearchStateChanged();
    }

    void fetchSquadAsync(const bool &in postLog = true) {
        if (g_selectedMatchmakingType !is null && g_selectedMatchmakingType.allowSquad) {
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
            applySquadExtras(g_activeSquad, res);
            // Sync the matchmaking type for non-owners when the owner changes it
            if (g_activeSquad !is null && g_activeSquad.matchmakingTypeId != g_lastSquadMatchmakingTypeId) {
                g_lastSquadMatchmakingTypeId = g_activeSquad.matchmakingTypeId;
                SyncSquadMatchmakingType(g_activeSquad.matchmakingTypeId);
            }
            handleSearchStateChanged();
        }
    }
}