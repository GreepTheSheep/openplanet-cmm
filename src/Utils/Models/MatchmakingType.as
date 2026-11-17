class MatchmakingType {
    int id;
    string name;
    uint teams;
    uint playersPerTeams;
    bool isDisabled;
    int placementMatches;
    bool allowSquad;
    MatchmakingTypeSeason@ season;
    MatchmakingTypeSeason@ nextSeason;

    MatchmakingType(const Json::Value &in json) {
        id = json["id"];
        name = json["name"];
        teams = json["teams"];
        playersPerTeams = json["playersPerTeams"];
        isDisabled = json["isDisabled"];
        placementMatches = json["placementMatches"];
        allowSquad = json["allowSquad"];
        if (json.HasKey("season") && json["season"].GetType() != Json::Type::Null) @season = MatchmakingTypeSeason(json["season"]);
        if (json.HasKey("nextSeason") && json["nextSeason"].GetType() != Json::Type::Null) @nextSeason = MatchmakingTypeSeason(json["nextSeason"]);
    }
}