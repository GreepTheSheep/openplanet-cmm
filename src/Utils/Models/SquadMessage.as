class SquadMessage {
    string accountId;
    string playerName;
    string message;
    int64 timestamp;

    SquadMessage(const Json::Value &in json) {
        accountId = json["accountId"];
        playerName = json["playerName"];
        message = json["message"];
        timestamp = json["timestamp"];
    }
}