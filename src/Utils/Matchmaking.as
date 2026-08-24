namespace Matchmaking {
    void getMatchmakingTypes() {
        g_matchmakingTypes.RemoveRange(0, g_matchmakingTypes.Length);
        Json::Value@ res = API::GetAsync(Setting_BaseURL + "/matchmaking/types");
        for (uint mt = 0; mt < res["types"].Length; mt++) {
            MatchmakingType@ matchmakingType = MatchmakingType(res["types"][mt]);
            g_matchmakingTypes.InsertLast(matchmakingType);
        }
    }

    void handleSocketData(const string &in dataType, const Json::Value &in data) {
        if (g_tcpSocket.connected) {
            if (dataType == "matchmakingQueued" || dataType == "matchmakingUnqueued") {
                g_queuePlayersCount = data["queueLength"];
            } else if (dataType == "matchmakingMatch") {
                g_inMatch = true;
                @g_matchInfo = Match(data["match"]);

                // Send match found notification
                Log::Log("Match found !", true);
                Audio::PlaySound(Audio::Sounds::MatchFound);
            } else if (dataType == "matchmakingEnded") {
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
            } else if (dataType == "matchmakingStatus") {
                if (g_matchInfo !is null) {
                    g_matchInfo.status = data["status"];
                    if (g_matchInfo.tmServer !is null && g_matchInfo.tmServer.quickJoinLink != "") {
                        if (!g_connectedToMatchGameServer && g_matchInfo.status.ToLower().StartsWith("waiting for players")) {
                            TM::JoinServer(g_matchInfo.tmServer.quickJoinLink);
                        }
                    }
                }
            } else if (dataType == "matchmakingMap") {
                if (g_matchInfo !is null) {
                    @g_matchInfo.map = TMMap(data["map"]);
                }
            } else {
                if (Meta::IsDeveloperMode()) Log::Warn("Unbound matchmaking socket '"+dataType+"': " + Json::Write(data));
            }
        }
    }
}