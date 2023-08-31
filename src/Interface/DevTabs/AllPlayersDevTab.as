class AllPlayersDevTab : Tab {
    Net::HttpRequest@ m_request;
    bool isError = false;
    string errorMsg = "";
    bool isLoading = false;
    array<Player@> allPlayers;
    string u_search;
    uint64 u_typingStart;
    int resLength = 0;

    string GetLabel() override { return "All Players"; }
    bool IsVisible() override { return g_connectedPlayer.hasPermission("list_all_players"); }

    void StartRequest()
    {
        isLoading = true;
        string url = Setting_BaseURL+"/admin/players/all";
        string urlParams = "";
        dictionary params;

        if (u_search.Length > 2) {
            params.Set("s", u_search);
        }

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

        @m_request = API::Get(url + urlParams);
    }

    void Reload() override {
        allPlayers.RemoveRange(0, allPlayers.Length);
        StartRequest();
    }

    void CheckStartRequest()
    {
        // If there's not already a request and the window is appearing, we start a new request
        if (m_request is null && UI::IsWindowAppearing()) {
            Reload();
        }

        if (m_request !is null) {
            return;
        }

        if (u_typingStart == 0) {
            return;
        }

        if (Time::Now > u_typingStart + 1000) {
            u_typingStart = 0;
            StartRequest();
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
            if (Meta::IsDeveloperMode()) trace("AllPlayersDevTab::CheckRequest: " + res);
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

            for (uint i = 0; i < json["results"].Length; i++) {
                Player@ player = Player(json["results"][i]);
                allPlayers.InsertLast(player);
            }

            resLength = json["length"];
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

        if (UI::BlueButton(Icons::Refresh)) Reload();

        UI::SameLine();
        UI::Text("Search:");
        UI::SameLine();
        bool changed = false;
        u_search = UI::InputText("##PlayerSearch", u_search, changed);
        if (changed) {
            u_typingStart = Time::Now;
            allPlayers.RemoveRange(0, allPlayers.Length);
            resLength = 0;
        }
        if (resLength > 0) {
            UI::SameLine();
            UI::Text(resLength + " results.");
        }

        if (allPlayers.Length == 0 && u_typingStart == 0) {
            UI::Text("\\$f00" + Icons::ExclamationTriangle + " \\$zPlayers list is empty");
            return;
        }

        if (UI::BeginTable("allPlayersList", 6, UI::TableFlags(UI::TableFlags::Resizable | UI::TableFlags::NoSavedSettings | UI::TableFlags::SizingStretchProp | UI::TableFlags::ScrollY))) {
            UI::TableSetupScrollFreeze(0, 1);
            PushTabStyle();
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Points", UI::TableColumnFlags::WidthFixed, 50);
            UI::TableSetupColumn("Connexion Date", UI::TableColumnFlags::WidthFixed, 150);
            UI::TableSetupColumn("Plugin Version", UI::TableColumnFlags::WidthFixed, 60);
            UI::TableSetupColumn("IP", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 80);
            UI::TableHeadersRow();
            PopTabStyle();

            UI::ListClipper clipper(allPlayers.Length);
            while(clipper.Step()) {
                for(int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
                {
                    UI::PushID("ResCoPlayer"+i);
                    Player@ player = allPlayers[i];
                    UI::TableNextRow();

                    UI::TableSetColumnIndex(0);
                    UI::Text(player.displayName);
                    UI::SetPreviousTooltip(player.accountId);
                    if (UI::IsItemClicked()) {
                        IO::SetClipboard(player.accountId);
                        UI::ShowNotification(Icons::Clipboard + " Account ID copied to clipboard");
                    }

                    UI::TableSetColumnIndex(1);
                    UI::Text(tostring(player.points));
                    UI::SetPreviousTooltip("Rank: " + player.rank);

                    UI::TableSetColumnIndex(2);
                    UI::Text(Time::FormatString("%F %X", player.lastLogonTimestamp));

                    UI::TableSetColumnIndex(3);
                    UI::Text(player.lastPluginVersion);

                    UI::TableSetColumnIndex(4);
                    UI::Text(player.lastIpAddress);

                    UI::TableSetColumnIndex(5);
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