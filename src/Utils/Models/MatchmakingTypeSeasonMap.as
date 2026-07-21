class MatchmakingTypeSeasonMap {
    int id;
    int mxMapPackId;
    string mxMapId;
    string uid;
    string name;
    string gbxMapName;
    string uploaderName;
    string downloadedAt;

    MatchmakingTypeSeasonMap(const Json::Value &in json) {
        id = json["id"];
        mxMapPackId = json["mxMapPackId"];
        mxMapId = json["mxMapId"];
        uid = json["uid"];
        name = json["name"];
        gbxMapName = json["gbxMapName"];
        uploaderName = json["uploaderName"];
        if (json.HasKey("downloadedAt") && json["downloadedAt"].GetType() != Json::Type::Null) downloadedAt = json["downloadedAt"];
    }
}

class MatchmakingTypeSeasonMapPack {
    int seasonId;
    int mxMapPackId;
    string mxMapPackSecret;
    array<MatchmakingTypeSeasonMap@> maps;

    MatchmakingTypeSeasonMapPack(const Json::Value &in json) {
        seasonId = json["seasonId"];
        if (json.HasKey("mxMapPackId") && json["mxMapPackId"].GetType() != Json::Type::Null) mxMapPackId = json["mxMapPackId"];
        if (json.HasKey("mxMapPackSecret") && json["mxMapPackSecret"].GetType() != Json::Type::Null) mxMapPackSecret = json["mxMapPackSecret"];
        for (uint t = 0; t < json["maps"].Length; t++) {
            maps.InsertLast(MatchmakingTypeSeasonMap(json["maps"][t]));
        }
    }
}