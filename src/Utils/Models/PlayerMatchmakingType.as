class PlayerMatchmakingType {
    int matchmakingTypeId;
    int points;
    int64 matchesPlayed;
    int64 matchesWin;
    int64 matchesDraw;
    int64 matchesLoss;
    int seasonId;

    PlayerMatchmakingType(const Json::Value &in json) {
        matchmakingTypeId = json["matchmakingTypeId"];
        points = json["points"];
        matchesPlayed = json["matchesPlayed"];
        matchesWin = json["matchesWin"];
        matchesDraw = json["matchesDraw"];
        matchesLoss = json["matchesLoss"];
        seasonId = json["seasonId"];
    }
}