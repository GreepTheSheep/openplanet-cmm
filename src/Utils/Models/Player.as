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
    int featuredBadgeId;
    Badge@ featuredBadge;
    array<PlayerBadge@> badges;

    private uint64 NextFetchBadgesTimestamp;

    Player(const Json::Value &in json) {
        id = json["id"];
        accountId = json["accountId"];
        displayName = json["displayName"];
        for (uint mt = 0; mt < json["matchmakingTypes"].Length; mt++){
            matchmakingTypes.InsertLast(PlayerMatchmakingType(json["matchmakingTypes"][mt]));
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
        if (json.HasKey("featuredBadgeId") && json["featuredBadgeId"].GetType() != Json::Type::Null) featuredBadgeId = json["featuredBadgeId"];
        if (json.HasKey("badges") && json["badges"].GetType() == Json::Type::Array) {
            for (uint b = 0; b < json["badges"].Length; b++){
                badges.InsertLast(PlayerBadge(json["badges"][b]));
            }
        }
        if (json.HasKey("featuredBadge") && json["featuredBadge"].GetType() == Json::Type::Object) @featuredBadge = Badge(json["featuredBadge"]);

        if (json.HasKey("badges") || json.HasKey("featuredBadge")) NextFetchBadgesTimestamp = Time::Now + uint64(Math::Rand(600000, 900000));
        else NextFetchBadgesTimestamp = Time::Now;
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
            hasPermission("manage_badges") ||
            hasPermission("edit_mmtype") ||
            hasPermission("broadcast_messages") ||
            hasPermission("edit_user_notice");
    }

    void fetchBadgesAsync(const bool &in force = false) {
        if (!force && Time::Now < NextFetchBadgesTimestamp) return;
        dictionary params;
        params.Set("playerId", tostring(id));

        string urlParams = "";
        if (!params.IsEmpty()) {
            auto keys = params.GetKeys();
            for (uint i = 0; i < keys.Length; i++) {
                string key = keys[i];
                string value;
                params.Get(key, value);

                urlParams += (i == 0 ? "?" : "&");
                urlParams += key + "=" + Net::UrlEncode(value);
            }
        }
        Json::Value@ badgesJson = API::GetAsync(Setting_BaseURL + "/user/badges" + urlParams);

        if (badgesJson.HasKey("featuredBadgeId") && badgesJson["featuredBadgeId"].GetType() != Json::Type::Null) featuredBadgeId = badgesJson["featuredBadgeId"];
        else featuredBadgeId = 0;
        if (badgesJson.HasKey("featuredBadge") && badgesJson["featuredBadge"].GetType() == Json::Type::Object) @featuredBadge = Badge(badgesJson["featuredBadge"]);
        else @featuredBadge = null;

        badges.RemoveRange(0, badges.Length);
        if (badgesJson.HasKey("badges") && badgesJson["badges"].GetType() == Json::Type::Array) {
            for (uint b = 0; b < badgesJson["badges"].Length; b++){
                badges.InsertLast(PlayerBadge(badgesJson["badges"][b]));
            }
        }

        NextFetchBadgesTimestamp = Time::Now + uint64(Math::Rand(600000, 900000));
    }
}