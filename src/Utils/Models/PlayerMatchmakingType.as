class PlayerMatchmakingType {
    int matchmakingTypeId;
    int points;
    int matchesPlayed;
    int matchesWin;
    int matchesDraw;
    int matchesLoss;
    int seasonId;
    array<PlayerMatchmakingTypeRecentMatch@> recentMatches;

    PlayerMatchmakingType(const Json::Value &in json) {
        matchmakingTypeId = json["matchmakingTypeId"];
        points = json["points"];
        matchesPlayed = json["matchesPlayed"];
        matchesWin = json["matchesWin"];
        matchesDraw = json["matchesDraw"];
        matchesLoss = json["matchesLoss"];
        seasonId = json["seasonId"];
        for (uint m = 0; m < json["recentMatches"].Length; m++){
            recentMatches.InsertLast(PlayerMatchmakingTypeRecentMatch(json["recentMatches"][m]));
        }
    }
}

class PlayerMatchmakingTypeRecentMatch {
    int matchId;
    string startDate;
    int64 startDateTimestamp;
    uint ratingAfter;

    PlayerMatchmakingTypeRecentMatch(const Json::Value &in json) {
        matchId = json["matchId"];
        if (json.HasKey("startDate") && json["startDate"].GetType() != Json::Type::Null) startDate = json["startDate"];
        if (json.HasKey("startDateTimestamp") && json["startDateTimestamp"].GetType() != Json::Type::Null) startDateTimestamp = json["startDateTimestamp"];
        ratingAfter = json["ratingAfter"];
    }
}