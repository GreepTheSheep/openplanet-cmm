class MatchmakingType {
    int id;
    string name;
    uint teams;
    uint playersPerTeams;
    bool isDisabled;
    int baseKFactor;
    int placementKFactor;
    int placementMatches;
    int initialRating;
    int maxSquadSize;
    bool allowSquad;

    MatchmakingType(const Json::Value &in json) {
        id = json["id"];
        name = json["name"];
        teams = json["teams"];
        playersPerTeams = json["playersPerTeams"];
        isDisabled = json["isDisabled"];
        baseKFactor = json["baseKFactor"];
        placementKFactor = json["placementKFactor"];
        placementMatches = json["placementMatches"];
        initialRating = json["initialRating"];
        maxSquadSize = json["maxSquadSize"];
        allowSquad = json["allowSquad"];
    }
}