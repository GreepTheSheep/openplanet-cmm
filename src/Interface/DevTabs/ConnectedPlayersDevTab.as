class ConnectedPlayersDevTab : Tab {
    Net::HttpRequest@ m_request;
    Net::HttpRequest@ m_disconnectRequest;
    bool isError = false;
    string errorMsg = "";
    bool isLoading = false;
    array<Player@> connectedPlayers;

    string GetLabel() override { return "Connected Players"; }

    void StartRequest()
    {
        isLoading = true;
        string url = Setting_BaseURL+"/dev/players";

        @m_request = API::Get(url);
    }

    void Reload() override {
        connectedPlayers.RemoveRange(0, connectedPlayers.Length);
        StartRequest();
    }

    void CheckStartRequest()
    {
        // If there's not already a request and the window is appearing, we start a new request
        if (m_request is null && UI::IsWindowAppearing()) {
            Reload();
        }
    }

    void CheckRequest()
    {
        CheckStartRequest();

        // If there's a request, check if it has finished
        if (m_request !is null && m_request.Finished()) {
            isLoading = false;
            // Parse the response
            string res = m_request.String();
            if (Meta::IsDeveloperMode()) trace("ConnectedPlayersDevTab::CheckRequest: " + res);
            @m_request = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                isError = true;
                errorMsg = "Error while loading players list";
                Log::Error(errorMsg);
                return;
            }

            if (json.HasKey("error")) {
                isError = true;
                errorMsg = json["error"]["message"];
                Log::Error(errorMsg);
                return;
            }

            for (uint i = 0; i < json["connected"].Length; i++) {
                Player@ player = Player(json["connected"][i]);
                connectedPlayers.InsertLast(player);
            }
        }
    }

    void DisconnectPlayer(Player@ player) {
        string url = Setting_BaseURL+"/dev/player/disconnect";
        Json::Value@ postJson = Json::Object();
        postJson["accountId"] = player.accountId;

        @m_disconnectRequest = API::Post(url, Json::Write(postJson));
    }

    void CheckDisconnectPlayerRequest()
    {
        // If there's a request, check if it has finished
        if (m_disconnectRequest !is null && m_disconnectRequest.Finished()) {
            isLoading = false;
            // Parse the response
            string res = m_disconnectRequest.String();
            if (Meta::IsDeveloperMode()) trace("ConnectedPlayersDevTab::CheckDisconnectPlayerRequest: " + res);
            @m_disconnectRequest = null;
            Reload();
        }
    }

    void Render() override
    {
        CheckRequest();

        if (isLoading) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading...");
            return;
        }

        if (isError) {
            UI::Text("\\$f00" + Icons::ExclamationTriangle + " \\$z" + errorMsg);
            return;
        }

        if (UI::Button(Icons::Refresh)) Reload();

        if (connectedPlayers.Length == 0) {
            UI::Text("\\$f00" + Icons::ExclamationTriangle + " \\$zConnected players list is empty");
            return;
        }

        CheckDisconnectPlayerRequest();
        if (UI::BeginTable("ConnectedPlayersList", 7, UI::TableFlags::Resizable | UI::TableFlags::Sortable | UI::TableFlags::NoSavedSettings | UI::TableFlags::SizingStretchProp | UI::TableFlags::ScrollY)) {
            UI::TableSetupScrollFreeze(0, 1);
            PushTabStyle();
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Rank", UI::TableColumnFlags::WidthFixed, 50);
            UI::TableSetupColumn("Connexion Date", UI::TableColumnFlags::WidthFixed, 150);
            UI::TableSetupColumn("Plugin Version", UI::TableColumnFlags::WidthFixed, 60);
            UI::TableSetupColumn("IP", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Group", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 80);
            UI::TableHeadersRow();
            PopTabStyle();

            UI::ListClipper clipper(connectedPlayers.Length);
            while(clipper.Step()) {
                for(int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
                {
                    UI::PushID("ResCoPlayer"+i);
                    Player@ player = connectedPlayers[i];
                    UI::TableNextRow();

                    UI::TableSetColumnIndex(0);
                    UI::Text(player.displayName);
                    UI::SetPreviousTooltip(player.accountId);

                    UI::TableSetColumnIndex(1);
                    UI::Text(player.points);
                    UI::SetPreviousTooltip("Rank: " + player.rank);

                    UI::TableSetColumnIndex(2);
                    UI::Text(Time::FormatString("%F %X", player.lastLogonTimestamp));

                    UI::TableSetColumnIndex(3);
                    UI::Text(player.lastPluginVersion);

                    UI::TableSetColumnIndex(4);
                    UI::Text(player.lastIpAddress);

                    UI::TableSetColumnIndex(5);
                    UI::Text(player.group.name);
                    string permsStr;
                    for (uint p = 0; p < player.group.permissions.Length; p++) {
                        permsStr += "- " + player.group.permissions[p].name + " (" + player.group.permissions[p].description + ")";
                        if (p != player.group.permissions.Length) permsStr += "\n";
                    }
                    UI::SetPreviousTooltip("ID: " + player.group.id + "\nPermissions:\n" + permsStr);

                    UI::TableSetColumnIndex(6);
                    if (UI::RedButton(Icons::Times)) {
                        DisconnectPlayer(player);
                    }
                    UI::SetPreviousTooltip("Disconnect Player");
                    UI::SameLine();
                    if (UI::RedButton(Icons::Ban)) {
                        Renderables::Add(DevBanPlayerModalDialog(player));
                    }
                    UI::SetPreviousTooltip("Ban Player");

                    UI::PopID();
                }
            }
            UI::EndTable();
        }
    }
}