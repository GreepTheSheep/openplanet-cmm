class AllPlayersDevTab : Tab {
    Net::HttpRequest@ m_request;
    Net::HttpRequest@ m_groupRequest;
    bool isError = false;
    string errorMsg = "";
    bool isLoading = false;
    array<Group@> allGroups;
    array<Player@> allPlayers;
    string u_search;
    uint64 u_typingStart;
    int resLength = 0;
    Player@ selectPlayer;
    Group@ selectGroup;

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
        @m_groupRequest = API::Get(Setting_BaseURL+"/admin/groups");
    }

    void Reload() override {
        allPlayers.RemoveRange(0, allPlayers.Length);
        allGroups.RemoveRange(0, allGroups.Length);
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
            isError = false;
            errorMsg = "";
        }

        if (m_groupRequest !is null && m_groupRequest.Finished()) {
            isLoading = false;
            // Parse the response
            string res = m_groupRequest.String();
            if (Meta::IsDeveloperMode()) trace("AllPlayersDevTab::CheckRequest: " + res);
            @m_groupRequest = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                isError = true;
                errorMsg = "Error while loading groups list";
                Log::Error(errorMsg);
                return;
            }

            if (json.HasKey("error")) {
                isError = true;
                errorMsg = json["error"]["message"];
                Log::Error(errorMsg);
                return;
            }

            for (uint i = 0; i < json["groups"].Length; i++) {
                Group@ group = Group(json["groups"][i]);
                allGroups.InsertLast(group);
            }
        }
    }

    void SetPlayerGroup() {
        int playersIndex = allPlayers.FindByRef(selectPlayer);
        Json::Value@ putJson = Json::Object();
        putJson["id"] = selectPlayer.accountId;
        putJson["group"] = selectGroup.id;

        Json::Value@ resPut = API::PutAsync(Setting_BaseURL+"/admin/player/group", Json::Write(putJson));
        Player@ newPlayer = Player(resPut);
        allPlayers.RemoveAt(playersIndex);
        allPlayers.InsertAt(playersIndex, newPlayer);
    }

    void Render() override
    {
        CheckRequest();

        if (isLoading) {
            UI::Text(Icons::AnimatedHourglass + " Loading...");
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
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Connexion Date", UI::TableColumnFlags::WidthFixed, 150);
            UI::TableSetupColumn("Plugin Version", UI::TableColumnFlags::WidthFixed, 60);
            UI::TableSetupColumn("IP", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Group", UI::TableColumnFlags::WidthFixed, 200);
            UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 80);
            UI::TableHeadersRow();

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
                    UI::Text(Time::FormatString("%F %X (%Z)", player.lastLogonTimestamp));

                    UI::TableSetColumnIndex(2);
                    UI::Text(player.lastPluginVersion);

                    UI::TableSetColumnIndex(3);
                    UI::Text(player.lastIpAddress);

                    UI::TableSetColumnIndex(4);
                    if (player.group !is null) {
                        if (g_connectedPlayer.hasPermission("edit_player_group")) {
                            UI::SetNextItemWidth(200 - 8);
                            if (UI::BeginCombo("##PlayerGroupSelect", player.group.nameWithIconColor)) {
                                for (uint j = 0; j < allGroups.Length; j++) {
                                    bool groupSelectChanged = false;
                                    groupSelectChanged = UI::Selectable(allGroups[j].nameWithIconColor+"##"+allGroups[j].id, groupSelectChanged);
                                    if (groupSelectChanged) {
                                        @selectPlayer = player;
                                        @selectGroup = allGroups[j];
                                        startnew(CoroutineFunc(SetPlayerGroup));
                                    }
                                }
                                UI::EndCombo();
                            }
                        } else {
                            UI::Text(player.group.nameWithIconColor);
                            string permsStr;
                            for (uint p = 0; p < player.group.permissions.Length; p++) {
                                permsStr += "- " + player.group.permissions[p].name + " (" + player.group.permissions[p].description + ")";
                                if (p != player.group.permissions.Length) permsStr += "\n";
                            }
                            UI::SetPreviousTooltip("ID: " + player.group.id + "\nPermissions:\n" + permsStr);
                        }
                    } else UI::Text("ID: " + player.groupId);

                    UI::TableSetColumnIndex(5);
                    if (g_connectedPlayer.hasPermission("manage_badges")) {
                        if (UI::Button(Icons::Kenney::BadgeAlt)) {
                            Renderables::Add(DevPlayerBadgesModalDialog(player));
                        }
                        UI::SetPreviousTooltip("Manage their badges");
                        UI::SameLine();
                    }
                    if (g_connectedPlayer.hasPermission("ban_player")) {
                        if (UI::RedButton(Icons::Ban)) {
                            Renderables::Add(DevBanPlayerModalDialog(player));
                        }
                        UI::SetPreviousTooltip("Ban Player");
                    }

                    UI::PopID();
                }
            }
            UI::EndTable();
        }
    }
}