class Badge {
    int id;
    string name;
    string description;
    string iconUrl;
    string createdAt;
    int64 createdAtTimestamp;

    Badge(const Json::Value &in json) {
        id = json["id"];
        name = json["name"];
        if (json.HasKey("description") && json["description"].GetType() != Json::Type::Null) description = json["description"];
        iconUrl = json["iconUrl"];
        if (json.HasKey("createdAt") && json["createdAt"].GetType() != Json::Type::Null) createdAt = json["createdAt"];
        if (json.HasKey("createdAtTimestamp") && json["createdAtTimestamp"].GetType() != Json::Type::Null) createdAtTimestamp = json["createdAtTimestamp"];
    }
}