class PlayerMatchmakingType {
    int matchmakingTypeId;
    int points;
    int64 rank;
    int seasonId;
    string seasonName;

    PlayerMatchmakingType(const Json::Value &in json) {
        matchmakingTypeId = json["matchmakingTypeId"];
        points = json["points"];
        if (json.HasKey("rank") && json["rank"].GetType() != Json::Type::Null) rank = json["rank"];
        seasonId = json["seasonId"];
        seasonName = json["seasonName"];
    }
}