class TcpSocketClient {
    Net::Socket@ socket;
    bool secure = false;
    bool connected = false;
    bool connectTimeout = false;
    string lastRead = "";
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
            if (Setting_BaseURL.StartsWith("http://")) port = 80;
            else if (Setting_BaseURL.StartsWith("https://")) {
                port = 443;
                secure = true;
            }
        }

        startnew(CoroutineFunc(connect));
    }

    void connect() {
        @socket = Net::Socket();
        bool connectStatus = socket.Connect(host, port, secure);
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

        connected = true;
        Log::Trace("Connected to socket server in "+connexionAttemptDelay+" ticks.");

        // Get the data from the LiveSplit Server
        while (socket !is null && socket.IsReady()) {
            if (socket.ReadLine(lastRead)) {
                lastRead = lastRead.Trim();
                if (Meta::IsDeveloperMode()) Log::Trace("TCP Socket Data: " + lastRead);
            }
            yield();
        }
    }

    void disconnect() {
        if (socket is null) return;
        socket.Close();
        @socket = null;
    }

    void send(const string&in data) {
        if (socket !is null) {
            if (Meta::IsDeveloperMode()) Log::Trace("Sending data to socket server: "+data);
            socket.WriteLine(data);
        }
    }
}