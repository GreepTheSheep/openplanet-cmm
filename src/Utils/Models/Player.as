class Player {
    uint id;
    string accountId;
    string displayName;
    uint points;
    int64 rank;
    int groupId;
    string lastLogon;
    int64 lastLogonTimestamp;
    string lastPluginVersion;
    string lastIpAddress;
    Group@ group;

    Player(const Json::Value &in json) {
        id = json["id"];
        accountId = json["accountId"];
        displayName = json["displayName"];
        points = json["points"];
        if (json.HasKey("rank") && json["rank"].GetType() != Json::Type::Null) rank = json["rank"];
        groupId = json["groupId"];
        lastLogon = json["lastLogon"];
        lastLogonTimestamp = json["lastLogonTimestamp"];
        lastPluginVersion = json["lastPluginVersion"]["fullVersion"];
        lastIpAddress = json["lastIpAddress"];
        @group = Group(json["group"]);
    }
}