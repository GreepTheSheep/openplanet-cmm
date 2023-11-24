class QueueTab : Tab {
    bool isError = false;
    // UI::Font@ Header = UI::LoadFont("DroidSans.ttf", 20);
    string errorMsg;

    string GetLabel() override { return Icons::Play; }
    string GetTooltip() override { return "Queue"; }
    vec4 GetColor() override { return vec4(0.05f, 0.47f, 0, 1); }

    void JoinQueueAsync() {
        Json::Value@ postJson = Json::Object();
        postJson["matchmakingId"] = g_selectedMatchmakingType.id;
        Json::Value@ res = API::PostAsync(Setting_BaseURL+"/matchmaking/join", Json::Write(postJson));

        if (res.GetType() == Json::Type::Null) {
            isError = true;
            errorMsg = "Error while loading matchmaking";
            Log::Error(errorMsg);
            return;
        }

        if (res.HasKey("error")) {
            int errCode = res["error"]["code"];
            errorMsg = res["error"]["message"];
            isError = true;
            Log::Error(errorMsg);
            return;
        }

        g_queueJoin = res["inQueue"];
        startnew(PingMatchmakingLoop);
    }

    void LeaveQueueAsync() {
        Json::Value@ postJson = Json::Object();
        postJson["matchmakingId"] = g_selectedMatchmakingType.id;
        Json::Value@ res = API::PostAsync(Setting_BaseURL+"/matchmaking/leave", Json::Write(postJson));

        if (res.GetType() == Json::Type::Null) {
            isError = true;
            errorMsg = "Error while loading matchmaking";
            Log::Error(errorMsg);
            return;
        }

        if (res.HasKey("error")) {
            int errCode = res["error"]["code"];
            errorMsg = res["error"]["message"];
            isError = true;
            Log::Error(errorMsg);
            return;
        }

        g_queueJoin = res["inQueue"];
    }

    void Render() override {
        if (g_userNotice.isEnabled) {
            UI::TextWrapped("\\$f90" + Icons::ExclamationTriangle + "\\$z " + g_userNotice.title);
            UI::TextWrapped(g_userNotice.description);
            UI::Separator();
        }
        UI::SetCursorPos(vec2(UI::GetWindowSize().x/2 - 25, UI::GetWindowSize().y - 25));
        if (!g_queueJoin && !g_inMatch) {
            if (UI::GreenButton(Icons::Play + " Enter queue")) startnew(CoroutineFunc(JoinQueueAsync));
        }
        if (g_queueJoin && !g_inMatch) {
            if (UI::RedButton(Icons::Stop + " Leave queue")) startnew(CoroutineFunc(LeaveQueueAsync));
        }
    }
}