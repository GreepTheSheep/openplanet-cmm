class ServerInfo {
    string name;
    string version;
    string gitCommit;
    string gitCommitDate;
    int64 gitCommitTimestamp;
    string deployement;
    bool isDevMode;
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
        deployement = json["deployement"];
        isDevMode = json["isDevMode"];
        startTimestamp = json["startTimestamp"];
        connectedPlayers = json["connectedPlayers"];
        userAgent = json["user-agent"];
        host = json["host"];
    }
}