class PlayerBadge {
    int id;
    int playerId;
    int badgeId;
    string awardedAt;
    int64 awardedAtTimestamp;
    int awardedBy;
    Badge@ badge;

    PlayerBadge(const Json::Value &in json) {
        id = json["id"];
        playerId = json["playerId"];
        badgeId = json["badgeId"];
        if (json.HasKey("awardedAt") && json["awardedAt"].GetType() != Json::Type::Null) awardedAt = json["awardedAt"];
        if (json.HasKey("awardedAtTimestamp") && json["awardedAtTimestamp"].GetType() != Json::Type::Null) awardedAtTimestamp = json["awardedAtTimestamp"];
        if (json.HasKey("awardedBy") && json["awardedBy"].GetType() != Json::Type::Null) awardedBy = json["awardedBy"];
        if (json.HasKey("badge") && json["badge"].GetType() == Json::Type::Object) @badge = Badge(json["badge"]);
    }
}