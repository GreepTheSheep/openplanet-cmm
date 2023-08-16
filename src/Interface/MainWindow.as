class MainWindow : Window {
    Tab@ m_homePageTab;
    // Tab@ m_YourProfileTab;
    Net::HttpRequest@ m_request;
    Player@ m_player;
    bool isError = false;
    string errorMsg = "";
    bool isLoading = false;

    MainWindow(){
        @m_homePageTab = QueueTab();
        AddTab(m_homePageTab);
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
        UI::Text("Points: " + m_player.points);
        UI::Text("Rank: " + m_player.rank + " / " + m_player.totalPlayers);
        vec2 BottomPos = UI::GetCursorPos();

        // UI::SetCursorPos(vec2(BasePos.x + 100, BasePos.y));

        UI::SetCursorPos(BottomPos);
    }

    void RenderFooter() override {
        UI::Separator();

        UI::Text(Icons::Users + " " + g_connectedPlayers);
        UI::SetPreviousTooltip("Number of players connected into " + PLUGIN_NAME_SHORT);
    }
}