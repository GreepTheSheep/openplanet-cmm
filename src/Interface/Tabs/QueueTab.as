class QueueTab : Tab {
    bool isError = false;
    // UI::Font@ Header = UI::LoadFont("DroidSans.ttf", 20);
    string errorMsg;
    UI::Font@ m_userNoticeExclamationFont = UI::LoadFont("DroidSans.ttf", 32, -1, -1, true, true, true);

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
            float width = 40;
            vec2 posTop = UI::GetCursorPos();
            UI::SetCursorPos(posTop + vec2(width / 3, 10));
            UI::PushFont(m_userNoticeExclamationFont);
            UI::Text(ColoredString(g_userNotice.icon));
            UI::PopFont();
            UI::SetCursorPos(posTop + vec2(width + 8, 0));
            UI::PushFont(g_headerFont);
            UI::TextWrapped(g_userNotice.title);
            UI::PopFont();
            UI::SetCursorPos(UI::GetCursorPos() + vec2(width + 8, 0));
            UI::TextWrapped(g_userNotice.description);
            vec2 posDesc = UI::GetCursorPos();
            UI::SetCursorPos(posDesc);
            UI::Separator();
        }
        if (!g_inMatch) {
            UI::SetCursorPos(vec2(UI::GetWindowSize().x/2.25 - 25, UI::GetWindowSize().y - 25));
            if (g_selectedMatchmakingType is null) {
                UI::BeginDisabled();
                UI::GrayButton("Loading");
                UI::EndDisabled();
            } else {
                UI::BeginDisabled(g_selectedMatchmakingType.isDisabled);
                if (g_selectedMatchmakingType.isDisabled) {
                    UI::GrayButton("Disabled");
                } else {
                    if (!g_queueJoin && !g_inMatch) {
                        if (UI::GreenButton(Icons::Play + " Enter queue")) startnew(CoroutineFunc(JoinQueueAsync));
                    }
                    if (g_queueJoin && !g_inMatch) {
                        if (UI::RedButton(Icons::Stop + " Leave queue")) startnew(CoroutineFunc(LeaveQueueAsync));
                    }
                }
                UI::EndDisabled();
            }
        } else {
            if (g_matchInfo !is null) {
                UI::Text(g_matchInfo.status);
                if (g_matchInfo.tmServer !is null && g_matchInfo.tmServer.joinLink != "") {
                    UI::Text("Join link: " + g_matchInfo.tmServer.joinLink);
                    if (UI::Button("Join")) {
                        CTrackMania@ app = cast<CTrackMania>(GetApp());
	                    app.ManiaPlanetScriptAPI.OpenLink(g_matchInfo.tmServer.quickJoinLink, CGameManiaPlanetScriptAPI::ELinkType::ManialinkBrowser);
                    }
                }
                if (g_matchInfo.map !is null) {
                    UI::Text("Map: " + ColoredString(g_matchInfo.map.Name));
                }
            }
        }
    }
}