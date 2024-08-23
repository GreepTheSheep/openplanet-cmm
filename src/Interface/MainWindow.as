class MainWindow : Window {
    Tab@ m_homePageTab;
    // Tab@ m_YourProfileTab;
    Net::HttpRequest@ m_getMeRequest;
    Net::HttpRequest@ m_getMMTypeRequest;
    Player@ m_player;
    string m_totalPlayers;
    bool isError = false;
    string errorMsg = "";
    bool isLoading = false;
    bool isLoadingMMType = true;
    bool matchmakingTypeSelectChanged = false;

    MainWindow(){
        @m_homePageTab = QueueTab();
        AddTab(m_homePageTab);
        AddTab(SquadTab());
    }

    void StartRequest()
    {
        isLoading = true;

        @m_getMeRequest = API::Get(Setting_BaseURL+"/user/me");
    }

    void CheckStartRequest()
    {
        // If there's not already a request and the window is appearing, we start a new request
        if (m_getMeRequest is null && UI::IsWindowAppearing()) {
            StartRequest();
        }
    }

    void CheckRequest()
    {
        CheckStartRequest();

        // If there's a request, check if it has finished
        if (m_getMeRequest !is null && m_getMeRequest.Finished()) {
            isLoading = false;
            // Parse the response
            string res = m_getMeRequest.String();
            if (Meta::IsDeveloperMode()) trace("HomePageTab::CheckRequest(User): " + res);
            @m_getMeRequest = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                isError = true;
                errorMsg = "Error while loading user profile";
                Log::Error(errorMsg);
                return;
            }

            if (json.HasKey("error")) {
                isError = true;
                errorMsg = json["error"]["message"];
                Log::Error(errorMsg);
                return;
            }

            @m_player = Player(json);
            @g_connectedPlayer = m_player;
            m_totalPlayers = json["totalPlayers"];
            if (g_selectedMatchmakingType is null) SelectMatchmakingType(g_matchmakingTypes[0]);
        }
    }

    string GetWindowId() override { return "YAMMMainWindow"; }

    void RenderHeader() override {
        CheckRequest();
        CheckRequestMMType();

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

        if (isLoadingMMType) {
            if (g_selectedMatchmakingType !is null && g_selectedPlayerMatchmakingType !is null) isLoadingMMType = false;
        }

        vec2 BasePos = UI::GetCursorPos();
        if (isLoadingMMType) UI::Text("Points: Loading...");
        else UI::Text("Points: " + g_selectedPlayerMatchmakingType.points);
        if (isLoadingMMType) UI::Text("Rank: Loading...");
        else UI::Text("Rank: " + g_selectedPlayerMatchmakingType.rank + " / " + m_totalPlayers);
        vec2 BottomPos = UI::GetCursorPos();

        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 215, BasePos.y + 12));

        UI::BeginDisabled(g_queueJoin || g_inMatch);
        UI::SetNextItemWidth(200);
        if (isLoadingMMType) {
            if (UI::BeginCombo("##MatchmakingTypeSelect", "Loading...")) UI::EndCombo();
        } else {
            if (UI::BeginCombo("##MatchmakingTypeSelect", g_selectedMatchmakingType.name)) {
                for (uint i = 0; i < g_matchmakingTypes.Length; i++) {
                    matchmakingTypeSelectChanged = UI::Selectable(g_matchmakingTypes[i].name+"##"+g_matchmakingTypes[i].id, matchmakingTypeSelectChanged);
                    if (matchmakingTypeSelectChanged) SelectMatchmakingType(g_matchmakingTypes[i]);
                }
                UI::EndCombo();
            }
        }
        UI::EndDisabled();

        UI::SetCursorPos(BottomPos);
    }

    void RenderFooter() override {
        UI::Separator();

        vec2 posOrig = UI::GetCursorPos();
        if (g_userNotice.isEnabled) {
            UI::Text(ColoredString(g_userNotice.icon));
            if (UI::IsItemHovered()) {
                UI::BeginTooltip();
                UI::PushFont(g_headerFont);
                UI::Text(ColoredString(g_userNotice.icon) + "\\$z   " + g_userNotice.title);
                UI::PopFont();
                UI::TextWrapped(g_userNotice.description);
                UI::EndTooltip();
            }
            UI::SameLine();
        }

        if (g_queueJoin || g_inMatch) {
            string queueStatusMsg = "";

            if (Time::Now - Math::Max(g_lastPingQueue,g_lastPingQueueSent) < (g_queueJoin ? 10000 : 30000)) {
                queueStatusMsg += UI::CreateColorCode(UI::hsv2rgb(vec3(0.33333 - Math::Abs(Time::Now - g_lastPingQueue) / 30000.0, 0.8, 1.0)));
            } else {
                queueStatusMsg += "\\$d00";
            }

            queueStatusMsg += "" + (g_lastPingQueue > g_lastPingQueueSent ? Icons::Download : Icons::Upload);
            if (g_queueJoin) queueStatusMsg += " \\$z" + Time::Format(Time::Now - g_queueJoinTime, false);
            else if (g_inMatch) queueStatusMsg += " \\$zIn match";

            UI::Text(queueStatusMsg);
            UI::SameLine();
        }

        if (!g_queueJoin) {
            UI::Text(Icons::Users + " " + g_connectedPlayerCount);
            UI::SetPreviousTooltip("Number of players connected into " + PLUGIN_NAME_SHORT);
        } else {
            string userIcon = Time::Stamp % 2 == 0 ? Icons::User : Icons::UserO;
            UI::Text(userIcon + " " + g_queuePlayersCount);
            UI::SetPreviousTooltip("Number of players queuing for " + g_selectedMatchmakingType.name);
        }

        UI::SameLine();

        if (g_activeSquad !is null) {
            if (g_selectedMatchmakingType !is null) {
                string textColor = "\\$666";
                if (g_activeSquad.players.Length > g_selectedMatchmakingType.playersPerTeams) textColor = "\\$f00";
                if (g_activeSquad.players.Length == g_selectedMatchmakingType.playersPerTeams) textColor = "\\$060";
                UI::Text(textColor + Icons::Kenney::Users + " " + g_activeSquad.players.Length + " / " + g_selectedMatchmakingType.playersPerTeams);
            } else UI::Text("\\$666" + Icons::Kenney::Users + " " + g_activeSquad.players.Length);
            UI::SetPreviousTooltip(g_activeSquad.name);
            UI::SameLine();
        }

        string versionString = "\\$666v"+Meta::ExecutingPlugin().Version;
        UI::SetCursorPos(vec2(UI::GetWindowSize().x-Draw::MeasureString(versionString).x-10, posOrig.y));
        UI::Text(versionString);
    }

    void SelectMatchmakingType(MatchmakingType@ matchmakingType) {
        isLoadingMMType = true;

        dictionary params;
        params.Set("id", tostring(matchmakingType.id));

        string urlParams = "";
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

        @m_getMMTypeRequest = API::Get(Setting_BaseURL+"/matchmaking/type/status"+urlParams);
    }

    void CheckRequestMMType() {
        if (m_getMMTypeRequest !is null && m_getMMTypeRequest.Finished()) {
            isLoadingMMType = false;
            // Parse the response
            string res = m_getMMTypeRequest.String();
            if (Meta::IsDeveloperMode()) trace("HomePageTab::CheckRequest(MMType): " + res);
            @m_getMMTypeRequest = null;
            auto json = Json::Parse(res);
            MatchmakingType@ resType = MatchmakingType(json);
            @g_selectedMatchmakingType = resType;

            for (uint p = 0; p < m_player.matchmakingTypes.Length; p++) {
                if (m_player.matchmakingTypes[p].matchmakingTypeId == g_selectedMatchmakingType.id) {
                    @g_selectedPlayerMatchmakingType = m_player.matchmakingTypes[p];
                    break;
                }
            }
        }
    }
}