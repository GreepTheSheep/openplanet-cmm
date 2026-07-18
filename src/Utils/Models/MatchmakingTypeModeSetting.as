class MatchmakingTypeModeSetting {
    int id;
    int matchmakingTypeId;
    string settingName;
    string settingType;
    string settingValue;

    MatchmakingTypeModeSetting(const Json::Value &in json) {
        id = json["id"];
        matchmakingTypeId = json["matchmakingTypeId"];
        settingName = json["settingName"];
        settingType = json["settingType"];
        settingValue = json["settingValue"];
    }
}