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

    Json::Value ToJson() {
        Json::Value json = Json::Object();

        try {
            json["id"] = id;
            json["matchmakingTypeId"] = matchmakingTypeId;
            json["settingName"] = settingName;
            json["settingType"] = settingType;
            json["settingValue"] = settingValue;
        } catch {
            Log::Warn("Error converting MatchmakingTypeModeSetting to json : " + getExceptionInfo());
        }

        return json;
    }
}