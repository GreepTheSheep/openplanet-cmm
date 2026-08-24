class TcpSocketClient {
    Net::Socket@ socket;
    bool secure = false;
    bool connected = false;
    bool connectTimeout = false;
    string lastRead = "";
    string lastWrite = "";
    int connexionAttemptDelay = 0;
    int connexionAttemptDelayMax = 300;
    string host;
    uint16 port;

    TcpSocketClient() {
        string fullHost = Setting_BaseURL;
        // We need to split protocol
        if (Setting_BaseURL.ToLower().StartsWith("http:")) fullHost = Setting_BaseURL.SubStr(7).ToLower();
        else if (Setting_BaseURL.ToLower().StartsWith("https:")) fullHost = Setting_BaseURL.SubStr(8).ToLower();

        if (fullHost.Contains(":")) {
            host = fullHost.SubStr(0, fullHost.IndexOf(":"));
            port = Text::ParseUInt(fullHost.SubStr(fullHost.IndexOf(":")+1));
        } else {
            host = fullHost;
            if (Setting_BaseURL.ToLower().StartsWith("http:")) port = 80;
            else if (Setting_BaseURL.ToLower().StartsWith("https:")) port = 443;
        }

        startnew(CoroutineFunc(connect));
    }

    void connect() {
        @socket = Net::Socket();
        bool connectStatus = socket.Connect(host, port, port == 443 || secure);
        if (!connectStatus) {
            Log::Error("Failed to connect to Socket server");
            return;
        }

        while (!socket.IsReady()) {
            yield();
            if (connexionAttemptDelay >= connexionAttemptDelayMax) {
                Log::Error("Failed to connect to Socket server. (Timeout)");
                connectTimeout = true;
                return;
            }
            connexionAttemptDelay++;
        }

        // Send the player token to initalize the socket to the player.
        // Server will handle this token and will assign to the player.
        dictionary headers;
        headers.Set("token", Auth::AccountToken);

        string headersString = "";
        if (!headers.IsEmpty()) {
            auto keys = headers.GetKeys();
            for (uint i = 0; i < keys.Length; i++) {
                string key = keys[i];
                string value;
                headers.Get(key, value);

                if (i > 0) headersString += "&";
                headersString += key + "=" + Net::UrlEncode(value);
            }
        }
        socket.WriteRaw(headersString);

        if (Meta::IsDeveloperMode()) Log::Trace("Connected to socket server in "+connexionAttemptDelay+" ticks.");
        startnew(CoroutineFunc(dataListener));
    }

    void disconnect() {
        if (socket is null || !connected) return;
        connected = false;
        socket.Close();
        @socket = null;
    }

    void onDataReceived() {
        try {
            Json::Value parsedJson = Json::Parse(lastRead);
            string dataMessage;
            if (parsedJson.GetType() == Json::Type::Null) return;

            if (parsedJson.HasKey("type") && parsedJson["type"].GetType() == Json::Type::String) {
                string socketDataType = parsedJson["type"];
                if (socketDataType == "handshake") {
                    if (parsedJson.HasKey("message") && parsedJson["message"].GetType() == Json::Type::String) dataMessage = parsedJson["message"];
                    if (Meta::IsDeveloperMode() && dataMessage.Length > 0) Log::Trace(dataMessage);
                    if (parsedJson.HasKey("status") && parsedJson["status"].GetType() == Json::Type::Boolean) {
                        connected = parsedJson["status"];
                        if (connected) {
                            Log::Trace("TCP Handshake OK");
                            startnew(CoroutineFunc(pingSweep));
                        }
                    }
                } else if (socketDataType == "pong") {
                    // Received after sending a ping from pingSweep, do nothing.
                } else if (socketDataType == "userNotification") {
                    string notificationType = parsedJson["notificationType"];
                    string message = parsedJson["message"];
                    if (notificationType == "log") Log::Log("Live Information from admins:\n\n" + message, true);
                    else if (notificationType == "warn") Log::Warn("Live Warning from admins:\n\n" + message, true);
                    else if (notificationType == "alert") Renderables::Add(BroadcastNotificationModalDialog(message));
                    else Log::Log("Silent message from admins: " + message);
                } else if (socketDataType == "notice") {
                    // User notice has been updated for everyone, update it on g_userNotice
                    g_userNotice.isEnabled = parsedJson["isEnabled"];
                    g_userNotice.icon = parsedJson["icon"];
                    g_userNotice.title = parsedJson["title"];
                    g_userNotice.description = parsedJson["description"];
                } else if (socketDataType.StartsWith("squad")) {
                    Squad::handleSocketData(socketDataType, parsedJson);
                } else {
                    Log::Warn("TCP Data received - Unknown type: " + socketDataType);
                    if (Meta::IsDeveloperMode()) Log::Log(lastRead);
                }
            }
        } catch {
            Log::Warn("Error while parsing TLS Socket data: " + getExceptionInfo());
        }
    }

    void send(const string&in data) {
        if (socket !is null) {
            lastWrite = data;
            socket.WriteLine(data);
        }
    }

    void pingSweep() {
        while (socket !is null && socket.IsReady()) {
            sleep(30000);
            try {
                Json::Value pingJson = Json::Object();
                pingJson["type"] = "ping";
                send(Json::Write(pingJson));
            } catch {
                if (Meta::IsDeveloperMode()) Log::Warn("Socket ping - Error while sending : " + getExceptionInfo());
            }
        }
    }

    void dataListener() {
        while (socket !is null && socket.IsReady()) {
            string rawReceivedData;
            if (socket.ReadLine(rawReceivedData)) {
                lastRead = rawReceivedData.Trim();
                onDataReceived();
            }
            yield();
        }
    }
}