class MatchHistory {
    int id;
    int playerId;
    int matchmakingTypeId;
    int seasonId;
    int matchId;
    int ratingBefore;
    int ratingAfter;
    int delta;
    int kFactor;
    string matchResult;
    bool isSquad;
    bool isPlacement;
    string calculatedAt;
    int64 calculatedAtTimestamp;

    MatchHistory(const Json::Value &in json) {
        id = json["id"];
        playerId = json["playerId"];
        matchmakingTypeId = json["matchmakingTypeId"];
        seasonId = json["seasonId"];
        matchId = json["matchId"];
        ratingBefore = json["ratingBefore"];
        ratingAfter = json["ratingAfter"];
        delta = json["delta"];
        kFactor = json["kFactor"];
        matchResult = json["matchResult"];
        isSquad = json["isSquad"];
        isPlacement = json["isPlacement"];
        if (json.HasKey("calculatedAt") && json["calculatedAt"].GetType() != Json::Type::Null) calculatedAt = json["calculatedAt"];
        if (json.HasKey("calculatedAtTimestamp") && json["calculatedAtTimestamp"].GetType() != Json::Type::Null) calculatedAtTimestamp = json["calculatedAtTimestamp"];
    }
}