class TmServer {
    int id;
    string login;
    int matchmakingTypeId;
    bool inUse;
    int serverPort;
    string joinLink;
    string quickJoinLink;

    TmServer(const Json::Value &in json) {
        id = json["id"];
        login = json["login"];
        matchmakingTypeId = json["matchmakingTypeId"];
        inUse = json["inUse"];
        serverPort = json["serverPort"];
        if (json["joinLink"].GetType() == Json::Type::String) {
            joinLink = json["joinLink"];
            quickJoinLink = Regex::Replace(joinLink, "#join=", "#qjoin=");
        }
    }
}