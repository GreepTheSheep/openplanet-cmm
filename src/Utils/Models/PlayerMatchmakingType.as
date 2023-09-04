class PlayerMatchmakingType {
    int matchmakingTypeId;
    int points;
    int64 rank;

    PlayerMatchmakingType(const Json::Value &in json) {
        matchmakingTypeId = json["matchmakingTypeId"];
        points = json["points"];
        if (json.HasKey("rank") && json["rank"].GetType() != Json::Type::Null) rank = json["rank"];
    }
}