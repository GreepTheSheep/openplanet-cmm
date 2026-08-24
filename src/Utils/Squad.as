namespace Squad {
    awaitable@ squadFetchLoopCoroutine;

    void fetchSquadLoop() {
        if (!g_tcpSocket.connected)
            while(!g_tcpSocket.connected && g_activeSquad !is null) {
                sleep(1500);
                fetchSquadAsync(false);
            }
    }

    void handleSocketData(const string &in dataType, const Json::Value &in data) {
        if (g_tcpSocket.connected && g_activeSquad !is null) {
            if (dataType == "squadMatchmakingType") {
                int dataMmTypeId = data["matchmakingTypeId"];
                SyncSquadMatchmakingType(dataMmTypeId);
            } else if (dataType == "squadMessage") {
                // Double message prevention by checking its timestamp, accountId and content
                int64 messageTimestamp = data["timestamp"];
                string messageAccountId = data["accountId"];
                string messageContent = data["message"];
                if (g_activeSquad.messages[0].timestamp == messageTimestamp && g_activeSquad.messages[0].accountId == messageAccountId && g_activeSquad.messages[0].message == messageContent) return;

                g_activeSquad.messages.InsertAt(0, SquadMessage(data));
            } else if (dataType == "squadPlayerReady") {
                string accountId = data["accountId"];
                bool ready = data["ready"];
                g_activeSquad.readyStates.Set(accountId, ready);
            } else if (dataType == "squadResetReady") {
                g_activeSquad.readyStates.DeleteAll();
            } else if (dataType == "squadSearching") {
                g_activeSquad.isSearching = data["isSearching"];
            } else if (dataType == "squadPlayerJoined") {
                // Double same player prevention by checking its accountId
                string playerJoinedAccountId = data["player"]["accountId"];
                for (uint p = 0; p < g_activeSquad.players.Length; p++) {
                    if (g_activeSquad.players[p].accountId == playerJoinedAccountId) return;
                }

                g_activeSquad.players.InsertLast(Player(data["player"]));
            } else if (dataType == "squadPlayerLeft" || dataType == "squadPlayerKicked") {
                string accountId = data["accountId"];
                for (uint p = 0; p < g_activeSquad.players.Length; p++) {
                    if (g_activeSquad.players[p].accountId == accountId) {
                        g_activeSquad.players.RemoveAt(p);
                        break;
                    }
                }
            } else if (dataType == "squadNewOwner") {
                g_activeSquad.ownerPlayer = data["ownerAccountId"];
            } else {
                if (Meta::IsDeveloperMode()) Log::Warn("Unknown squad socket '"+dataType+"': " + Json::Write(data));
            }
        }
    }

    void applySquadExtras(Squad@ squad, const Json::Value &in res) {
        if (squad is null || g_tcpSocket.connected) return;
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
        if (!g_tcpSocket.connected) @g_activeSquad = Squad(res["squad"]);
        applySquadExtras(g_activeSquad, res);
        handleSearchStateChanged();
    }

    void SyncSquadMatchmakingType(int squadTypeId) {
        if (squadTypeId <= 0) return;
        if (g_selectedMatchmakingType !is null && g_selectedMatchmakingType.id == squadTypeId) return;
        if (g_activeSquad is null) return;
        if (g_connectedPlayer.accountId == g_activeSquad.ownerPlayer) return; // sync for other players only, the owner (host) manages it
        for (uint i = 0; i < g_matchmakingTypes.Length; i++) {
            if (g_matchmakingTypes[i].id == squadTypeId) {
                @g_selectedMatchmakingType = g_matchmakingTypes[i];
                break;
            }
        }
        for (uint p = 0; p < g_connectedPlayer.matchmakingTypes.Length; p++) {
            if (g_connectedPlayer.matchmakingTypes[p].matchmakingTypeId == g_selectedMatchmakingType.id) {
                @g_selectedPlayerMatchmakingType = g_connectedPlayer.matchmakingTypes[p];
                break;
            }
        }
    }

    void fetchSquadAsync(const bool &in postLog = true) {
        if (g_selectedMatchmakingType !is null && g_selectedMatchmakingType.allowSquad) {
            Json::Value@ res = API::GetAsync(Setting_BaseURL+"/squad", postLog);

            if (res.GetType() == Json::Type::Null) {
                Log::Error("Error while loading squad");
                @g_activeSquad = null;
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
            SyncSquadMatchmakingType(g_activeSquad.matchmakingTypeId);
            handleSearchStateChanged();
        }
    }
}