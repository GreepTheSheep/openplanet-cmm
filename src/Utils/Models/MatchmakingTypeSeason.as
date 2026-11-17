class MatchmakingTypeSeason {
    int id;
    uint number;
    string name;
    bool isActive;
    bool isUpcoming;
    int mxMapPackId;
    string mxMapPackSecret;
    string startDate;
    int64 startDateTimestamp;
    string endDate;
    int64 endDateTimestamp;

    MatchmakingTypeSeason(const Json::Value &in json) {
        id = json["id"];
        number = json["number"];
        name = json["name"];
        isActive = json["isActive"];
        if (json.HasKey("isUpcoming") && json["isUpcoming"].GetType() == Json::Type::Boolean) isUpcoming = json["isUpcoming"];
        else isUpcoming = false;
        if (json.HasKey("mxMapPackId") && json["mxMapPackId"].GetType() == Json::Type::Number) mxMapPackId = json["mxMapPackId"];
        if (json.HasKey("mxMapPackSecret") && json["mxMapPackSecret"].GetType() == Json::Type::String) mxMapPackSecret = json["mxMapPackSecret"];
        if (json.HasKey("startDate") && json["startDate"].GetType() != Json::Type::Null) startDate = json["startDate"];
        if (json.HasKey("startDateTimestamp") && json["startDateTimestamp"].GetType() != Json::Type::Null) startDateTimestamp = json["startDateTimestamp"];
        if (json.HasKey("endDate") && json["endDate"].GetType() != Json::Type::Null) endDate = json["endDate"];
        if (json.HasKey("endDateTimestamp") && json["endDateTimestamp"].GetType() != Json::Type::Null) endDateTimestamp = json["endDateTimestamp"];
    }
}