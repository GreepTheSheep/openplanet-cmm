class MatchmakingLeaderboard {
    int playerId;
    int matchmakingTypeId;
    int seasonId;
    int rating;
    int matchesPlayed;
    int matchesWin;
    int matchesDraw;
    int matchesLoss;
    string accountId;
    string displayName;
    int rank;

    MatchmakingLeaderboard(const Json::Value &in json) {
        playerId = json["playerId"];
        matchmakingTypeId = json["matchmakingTypeId"];
        seasonId = json["seasonId"];
        rating = json["rating"];
        matchesPlayed = json["matchesPlayed"];
        matchesWin = json["matchesWin"];
        matchesDraw = json["matchesDraw"];
        matchesLoss = json["matchesLoss"];
        accountId = json["accountId"];
        displayName = json["displayName"];
        rank = json["rank"];
    }
}