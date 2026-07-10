class MatchmakingTypeSeason {
    int id;
    uint number;
    string name;
    bool isActive;
    string startDate;
    int64 startDateTimestamp;
    string endDate;
    int64 endDateTimestamp;

    MatchmakingTypeSeason(const Json::Value &in json) {
        id = json["id"];
        number = json["number"];
        name = json["name"];
        isActive = json["isActive"];
        if (json.HasKey("startDate") && json["startDate"].GetType() != Json::Type::Null) startDate = json["startDate"];
        if (json.HasKey("startDateTimestamp") && json["startDateTimestamp"].GetType() != Json::Type::Null) startDateTimestamp = json["startDateTimestamp"];
        if (json.HasKey("endDate") && json["endDate"].GetType() != Json::Type::Null) endDate = json["endDate"];
        if (json.HasKey("endDateTimestamp") && json["endDateTimestamp"].GetType() != Json::Type::Null) endDateTimestamp = json["endDateTimestamp"];
    }
}