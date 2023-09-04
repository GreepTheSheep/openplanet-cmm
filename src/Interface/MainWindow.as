class MainWindow : Window {
    Tab@ m_homePageTab;
    // Tab@ m_YourProfileTab;
    Net::HttpRequest@ m_request;
    Player@ m_player;
    MatchmakingType@ selectedMatchmakingType;
    PlayerMatchmakingType@ selectedPlayerMatchmakingType;
    string m_totalPlayers;
    bool isError = false;
    string errorMsg = "";
    bool isLoading = false;
    bool matchmakingTypeSelectChanged = false;

    MainWindow(){
        @m_homePageTab = QueueTab();
        AddTab(m_homePageTab);
        AddTab(SquadTab());
    }

    void StartRequest()
    {
        isLoading = true;
        string url = Setting_BaseURL+"/user/me";

        @m_request = API::Get(url);
    }

    void CheckStartRequest()
    {
        // If there's not already a request and the window is appearing, we start a new request
        if (m_request is null && UI::IsWindowAppearing()) {
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
            if (Meta::IsDeveloperMode()) trace("HomePageTab::CheckRequest: " + res);
            @m_request = null;
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
            SelectMatchmakingType(g_matchmakingTypes[0]);
        }
    }

    string GetWindowId() override { return "YAMMMainWindow"; }

    void RenderHeader() override {
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

        vec2 BasePos = UI::GetCursorPos();
        UI::Text("Points: " + selectedPlayerMatchmakingType.points);
        UI::Text("Rank: " + selectedPlayerMatchmakingType.rank + " / " + m_totalPlayers);
        vec2 BottomPos = UI::GetCursorPos();

        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 215, BasePos.y + 12));

        UI::SetNextItemWidth(200);
        if (UI::BeginCombo("##MatchmakingTypeSelect", selectedMatchmakingType.name)) {
            for (uint i = 0; i < g_matchmakingTypes.Length; i++) {
                matchmakingTypeSelectChanged = UI::Selectable(g_matchmakingTypes[i].name+"##"+g_matchmakingTypes[i].id, matchmakingTypeSelectChanged);
                if (matchmakingTypeSelectChanged) SelectMatchmakingType(g_matchmakingTypes[i]);
            }
            UI::EndCombo();
        }

        UI::SetCursorPos(BottomPos);
    }

    void RenderFooter() override {
        UI::Separator();

        UI::Text(Icons::Users + " " + g_connectedPlayerCount);
        UI::SetPreviousTooltip("Number of players connected into " + PLUGIN_NAME_SHORT);
    }

    void SelectMatchmakingType(MatchmakingType@ matchmakingType) {
        @selectedMatchmakingType = matchmakingType;

        for (uint p = 0; p < m_player.matchmakingTypes.Length; p++) {
            if (m_player.matchmakingTypes[p].matchmakingTypeId == selectedMatchmakingType.id) {
                @selectedPlayerMatchmakingType = m_player.matchmakingTypes[p];
                break;
            }
        }
    }
}