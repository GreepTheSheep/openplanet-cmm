class PlayerMatchmakingType {
    int matchmakingTypeId;
    int points;
    int matchesPlayed;
    int matchesWin;
    int matchesDraw;
    int matchesLoss;
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