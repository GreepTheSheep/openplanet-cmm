class Match {
    int id;
    int matchmakingTypeId;
    string status;
    string tmServerLogin;
    TmServer@ tmServer;
    array<MatchTeam@> teams;
    TMMap@ map;

    Match(const Json::Value &in json) {
        id = json["id"];
        matchmakingTypeId = json["matchmakingTypeId"];
        status = json["status"];
        if (json["tmServer"].GetType() == Json::Type::Object) @tmServer = TmServer(json["tmServer"]);
        for (uint t = 0; t < json["teams"].Length; t++){
            MatchTeam@ team = MatchTeam(json["teams"][t]);
            teams.InsertLast(team);
        }
        if (json["map"].GetType() == Json::Type::Object) @map = TMMap(json["map"]);
    }
}