class Player {
    uint id;
    string accountId;
    string displayName;
    array<PlayerMatchmakingType@> matchmakingTypes;
    int groupId;
    string firstLogon;
    int64 firstLogonTimestamp;
    string lastLogon;
    int64 lastLogonTimestamp;
    string lastPluginVersion;
    string lastIpAddress;
    bool isTrustedDeveloper;
    Group@ group;

    Player(const Json::Value &in json) {
        id = json["id"];
        accountId = json["accountId"];
        displayName = json["displayName"];
        for (uint mt = 0; mt < json["matchmakingTypes"].Length; mt++){
            PlayerMatchmakingType@ matchmakingType = PlayerMatchmakingType(json["matchmakingTypes"][mt]);
            matchmakingTypes.InsertLast(matchmakingType);
        }
        groupId = json["groupId"];
        firstLogon = json["firstLogon"];
        firstLogonTimestamp = json["firstLogonTimestamp"];
        lastLogon = json["lastLogon"];
        lastLogonTimestamp = json["lastLogonTimestamp"];
        lastPluginVersion = json["lastPluginVersion"]["fullVersion"];
        if (json.HasKey("lastIpAddress") && json["lastIpAddress"].GetType() != Json::Type::Null) lastIpAddress = json["lastIpAddress"];
        isTrustedDeveloper = json["isTrustedDeveloper"];
        if (json.HasKey("group") && json["group"].GetType() != Json::Type::Null) @group = Group(json["group"]);
    }

    bool hasPermission(const string &in permissionName) {
        if (group is null) return false;
        for (uint i = 0; i < group.permissions.Length; i++) {
            if (group.permissions[i].name == permissionName) return true;
        }
        return false;
    }

    bool canHaveAdminWindow() {
        return
            hasPermission("list_players") ||
            hasPermission("list_all_players") ||
            hasPermission("list_groups") ||
            hasPermission("edit_mmtype") ||
            hasPermission("edit_user_notice");
    }
}