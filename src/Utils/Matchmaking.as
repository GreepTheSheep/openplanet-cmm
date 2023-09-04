namespace Matchmaking {
    void getMatchmakingTypes() {
        g_matchmakingTypes.RemoveRange(0, g_matchmakingTypes.Length);
        Json::Value@ res = API::GetAsync(Setting_BaseURL + "/matchmaking/types");
        for (uint mt = 0; mt < res["types"].Length; mt++) {
            MatchmakingType@ matchmakingType = MatchmakingType(res["types"][mt]);
            g_matchmakingTypes.InsertLast(matchmakingType);
        }
    }
}