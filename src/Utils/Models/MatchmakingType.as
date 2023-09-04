class MatchmakingType {
    int id;
    string name;
    int teams;
    int playersPerTeams;

    MatchmakingType(const Json::Value &in json) {
        id = json["id"];
        name = json["name"];
        teams = json["teams"];
        playersPerTeams = json["playersPerTeams"];
    }
}