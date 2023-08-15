class Player {
    uint id;
    string accountId;
    string displayName;
    uint points;
    string rank;
    string totalPlayers;

    Player(const Json::Value &in json) {
        id = json["id"];
        accountId = json["accountId"];
        displayName = json["displayName"];
        points = json["points"];
        rank = json["rank"];
        totalPlayers = json["totalPlayers"];
    }
}