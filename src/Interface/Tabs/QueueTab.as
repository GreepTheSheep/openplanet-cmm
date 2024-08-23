class QueueTab : Tab {
    bool isError = false;
    // UI::Font@ Header = UI::LoadFont("DroidSans.ttf", 20);
    string errorMsg;
    string queueButtonMsg;
    UI::Font@ m_userNoticeExclamationFont = UI::LoadFont("DroidSans.ttf", 32, -1, -1, true, true, true);

    string GetLabel() override { return Icons::Play; }
    string GetTooltip() override { return "Queue"; }
    vec4 GetColor() override { return vec4(0.05f, 0.47f, 0, 1); }

    void JoinQueueAsync() {
        g_isPingingMatchmakingQueue = true;
        g_lastPingQueueSent = Time::Now;
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
        if (res.HasKey("queueLength")) g_queuePlayersCount = res["queueLength"];
        else g_queuePlayersCount = 0;

        g_queueJoinTime = Time::Now;
        g_isPingingMatchmakingQueue = false;

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
        if (g_queueJoin == false) g_queuePlayersCount = 0;
    }

    void Render() override {
        if (!g_inMatch) {
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
            UI::SetCursorPos(vec2((UI::GetWindowSize().x*.5) - (Draw::MeasureString(queueButtonMsg).x/2), UI::GetWindowSize().y - 25));
            if (g_selectedMatchmakingType is null) {
                UI::BeginDisabled();
                queueButtonMsg = Icons::Hourglass + " Loading";
                UI::GrayButton(queueButtonMsg);
                UI::EndDisabled();
            } else {
#if !FORCE_JOIN_MATCHMAKING
#if SIG_SCHOOL
                if (!Meta::IsSchoolModeWhitelisted()) {
                    UI::BeginDisabled();
                    queueButtonMsg = Icons::Times + " School Mode enabled";
                    UI::RedButton(queueButtonMsg);
                    UI::EndDisabled();
                } else
#endif
                if (g_selectedMatchmakingType.isDisabled) {
                    UI::BeginDisabled();
                    queueButtonMsg = Icons::Times + " Disabled";
                    UI::GrayButton(queueButtonMsg);
                    UI::EndDisabled();
                } else if (g_activeSquad !is null && g_activeSquad.players.Length > g_selectedMatchmakingType.playersPerTeams) {
                    UI::BeginDisabled();
                    queueButtonMsg = Icons::Times + " Too many players in squad";
                    UI::GrayButton(queueButtonMsg);
                    UI::EndDisabled();
                } else {
#endif
                    if (!g_queueJoin) {
                        queueButtonMsg = Icons::Play + " Enter queue";
                        if (UI::GreenButton(queueButtonMsg)) startnew(CoroutineFunc(JoinQueueAsync));
                    }
                    if (g_queueJoin) {
                        queueButtonMsg = Icons::Stop + " Leave queue";
                        if (UI::RedButton(queueButtonMsg)) startnew(CoroutineFunc(LeaveQueueAsync));
                    }
#if !FORCE_JOIN_MATCHMAKING
                }
#endif
            }
        } else {
            if (g_matchInfo !is null) {
                UI::Text(g_matchInfo.status);
                if (g_matchInfo.tmServer !is null) {
                    if (g_matchInfo.map !is null) {
                        UI::Text("Map: " + ColoredString(g_matchInfo.map.Name));
                        UI::Separator();
                    }
                    float width = UI::GetWindowSize().x / g_matchInfo.teams.Length;
                    float posX = 0;
                    vec2 posTop = UI::GetCursorPos();
                    for (uint t = 0; t < g_matchInfo.teams.Length; t++) {
                        if (t > 0) UI::SetCursorPos(posTop + vec2(posX, 0));
                        UI::BeginChild("MatchTeam"+t, vec2(width,0));
                        UI::Text(ColoredString("$" + g_matchInfo.teams[t].colorTM + g_matchInfo.teams[t].name));
                        UI::Separator();
                        for (uint p = 0; p < g_matchInfo.teams[t].players.Length; p++) {
                            UI::Text("- " + g_matchInfo.teams[t].players[p].displayName);
                            if (g_matchInfo.teams[t].players[p].group.icon.Length > 0) {
                                UI::SameLine();
                                UI::Text(g_matchInfo.teams[t].players[p].group.iconWithColor);
                                UI::SetPreviousTooltip(g_matchInfo.teams[t].players[p].group.name);
                            }
                            for (uint mt = 0; mt < g_matchInfo.teams[t].players[p].matchmakingTypes.Length; mt++) {
                                if (g_matchInfo.teams[t].players[p].matchmakingTypes[mt].matchmakingTypeId == g_selectedMatchmakingType.id) {
                                    UI::SameLine();
                                    UI::Text(g_matchInfo.teams[t].players[p].matchmakingTypes[mt].points + " points");
                                    if (g_matchInfo.teams[t].players[p].matchmakingTypes[mt].rank == -1)
                                        UI::SetPreviousTooltip("#" + g_matchInfo.teams[t].players[p].matchmakingTypes[mt].rank);
                                }
                            }
                        }
                        posX = posX + UI::GetWindowSize().x + 8;
                        UI::EndChild();
                    }
                    if ((
                            g_matchInfo.status.ToLower().StartsWith("waiting for players") ||
                            g_matchInfo.status.ToLower().StartsWith("match in progress")
                        ) &&
                        g_matchInfo.tmServer.quickJoinLink != "")
                    {
                        UI::SetCursorPos(vec2(UI::GetWindowSize().x/2.25 - 25, UI::GetWindowSize().y - 25));
                        if (UI::Button(Icons::Kenney::Reload + " Force Join")) TM::JoinServer(g_matchInfo.tmServer.quickJoinLink);
                    }
                }
            }
        }
    }
}