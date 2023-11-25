class MatchmakingType {
    int id;
    string name;
    uint teams;
    uint playersPerTeams;
    bool isDisabled;

    MatchmakingType(const Json::Value &in json) {
        id = json["id"];
        name = json["name"];
        teams = json["teams"];
        playersPerTeams = json["playersPerTeams"];
        isDisabled = json["isDisabled"];
    }
}