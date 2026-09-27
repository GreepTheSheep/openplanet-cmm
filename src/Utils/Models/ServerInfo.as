class ServerInfo {
    string name;
    string version;
    string gitCommit;
    string gitCommitDate;
    int64 gitCommitTimestamp;
    string nodeEnv;
    bool isDev;
    int64 startTimestamp;
    uint connectedPlayers;
    string userAgent;
    string host;

    ServerInfo(const Json::Value &in json) {
        name = json["name"];
        version = json["version"];
        gitCommit = json["gitCommit"];
        gitCommitDate = json["gitCommitDate"];
        gitCommitTimestamp = json["gitCommitTimestamp"];
        nodeEnv = json["nodeEnv"];
        isDev = json["isDev"];
        startTimestamp = json["startTimestamp"];
        connectedPlayers = json["connectedPlayers"];
        userAgent = json["user-agent"];
        host = json["host"];
    }
}