class QueueTab : Tab {
    bool isError = false;
    string errorMsg;
    string queueButtonMsg;
    bool isSquadToggleReadyClicked = false;
    bool isLeaveQueueClicked = false;

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
        isLeaveQueueClicked = true;
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
        isLeaveQueueClicked = false;
    }

    void SquadToggleReady(bool ready) {
        isSquadToggleReadyClicked = true;
        Json::Value@ postJson = Json::Object();
        postJson["ready"] = ready;
        Json::Value@ res = API::PostAsync(Setting_BaseURL+"/squad/ready", Json::Write(postJson));

        if (res.GetType() == Json::Type::Null) {
            isError = true;
            errorMsg = "Error while setting ready state";
            Log::Error(errorMsg);
            return;
        }
        if (res.HasKey("error")) {
            isError = true;
            errorMsg = res["error"]["message"];
            Log::Error(errorMsg);
            return;
        }
        isError = false;
        @g_activeSquad = Squad(res["squad"]);
        Squad::applySquadExtras(g_activeSquad, res);
        HandleSquadSearchStateChanged();
        isSquadToggleReadyClicked = false;
    }

    void HandleSquadSearchStateChanged() {
        if (g_activeSquad is null) return;
        if (g_activeSquad.isSearching) {
            if (!g_queueJoin && !g_inMatch) {
                g_queueJoin = true;
                g_queueJoinTime = Time::Now;
                startnew(PingMatchmakingLoop);
            }
        } else {
            if (g_queueJoin && !g_inMatch) {
                g_queueJoin = false;
            }
        }
    }

    void Render() override {
        if (!g_inMatch) {
            if (g_userNotice.isEnabled) {
                float width = 40;
                vec2 posTop = UI::GetCursorPos();
                UI::SetCursorPos(posTop + vec2(width / 3, 10));
                UI::PushFont(Fonts::UserNoticeIcon);
                UI::Text(Text::OpenplanetFormatCodes(g_userNotice.icon));
                UI::PopFont();
                UI::SetCursorPos(posTop + vec2(width + 8, 0));
                UI::PushFont(Fonts::Header);
                UI::TextWrapped(g_userNotice.title);
                UI::PopFont();
                UI::SetCursorPos(UI::GetCursorPos() + vec2(width + 8, 0));
                UI::Markdown(g_userNotice.description);
                vec2 posDesc = UI::GetCursorPos();
                UI::SetCursorPos(posDesc);
                UI::Separator();
            }

            if (g_selectedPlayerMatchmakingType !is null) {
                if (g_selectedPlayerMatchmakingType.matchesPlayed >= g_selectedMatchmakingType.placementMatches) {
                    vec2 posTop = UI::GetCursorPos();
                    array<float> recentMatchesPoints;
                    for (uint rm = 0; rm < g_selectedPlayerMatchmakingType.recentMatches.Length; rm++) {
                        recentMatchesPoints.InsertLast(g_selectedPlayerMatchmakingType.recentMatches[rm].ratingAfter);
                    }
                    UI::PushStyleColor(UI::Col::FrameBg, vec4(0,0,0,0));
                    UI::PushStyleColor(UI::Col::PlotLines, vec4(1,1,1,0.2));
                    UI::PushStyleColor(UI::Col::PlotLinesHovered, vec4(1,1,1,0.4));
                    UI::PushStyleColor(UI::Col::Text, vec4(0,0,0,0));
                    UI::PushStyleColor(UI::Col::PopupBg, vec4(0,0,0,0));
                    UI::SetNextItemWidth(UI::GetWindowSize().x + (4 * UI::GetScale()));
                    UI::PlotLines("##recentMatchesPointsGraph", recentMatchesPoints, 0, UI::GetWindowSize().y - 100);
                    UI::PopStyleColor(5);
                    if (UI::IsItemHovered()) {
                        vec4 graphRect = UI::GetItemRect();
                        vec2 mousePos = UI::GetMousePos();
                        mousePos = vec2(mousePos.x - graphRect.x, mousePos.y - graphRect.y);
                        mousePos = vec2(mousePos.x / graphRect.z, mousePos.y / graphRect.w);
                        uint index = uint(mousePos.x * g_selectedPlayerMatchmakingType.recentMatches.Length);
                        UI::SetCursorPos(posTop);
                        UI::PushStyleColor(UI::Col::Text, vec4(1,1,1,0.5));
                        UI::Text(g_selectedPlayerMatchmakingType.recentMatches[index].ratingAfter + "pts");
                        UI::PopStyleColor(1);
                    }
                }
            }

            RenderQueueButton();

            if (isError) {
                UI::Separator();
                UI::Text("\\$f00" + Icons::ExclamationTriangle + " \\$z" + errorMsg);
            }
        } else {
            if (g_matchInfo !is null) {
                UI::Text(g_matchInfo.status);
                if (g_matchInfo.tmServer !is null) {
                    if (g_matchInfo.map !is null) {
                        UI::Text("Map: " + Text::OpenplanetFormatCodes(g_matchInfo.map.Name));
                        UI::Separator();
                    }
                    float width = UI::GetWindowSize().x / g_matchInfo.teams.Length;
                    float posX = 0;
                    vec2 posTop = UI::GetCursorPos();
                    for (uint t = 0; t < g_matchInfo.teams.Length; t++) {
                        if (t > 0) UI::SetCursorPos(posTop + vec2(posX, 0));
                        UI::BeginChild("MatchTeam"+t, vec2(width,0));
                        UI::Text(Text::OpenplanetFormatCodes("$" + g_matchInfo.teams[t].colorTM + g_matchInfo.teams[t].name));
                        UI::Separator();
                        for (uint p = 0; p < g_matchInfo.teams[t].players.Length; p++) {
                            UI::Text("- " + g_matchInfo.teams[t].players[p].displayName);
                            if (g_matchInfo.teams[t].players[p].group.icon.Length > 0) {
                                UI::SameLine();
                                UI::Text(g_matchInfo.teams[t].players[p].group.iconWithColor);
                                UI::SetPreviousTooltip(g_matchInfo.teams[t].players[p].group.name);
                            }
                            for (uint mt = 0; mt < g_matchInfo.teams[t].players[p].matchmakingTypes.Length; mt++) {
                                if (
                                    g_matchInfo.teams[t].players[p].matchmakingTypes[mt].matchmakingTypeId == g_selectedMatchmakingType.id &&
                                    g_matchInfo.teams[t].players[p].matchmakingTypes[mt].matchesPlayed >= g_selectedMatchmakingType.placementMatches
                                ) {
                                    UI::SameLine();
                                    UI::Text(tostring(g_matchInfo.teams[t].players[p].matchmakingTypes[mt].points));
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
                        g_matchInfo.tmServer.quickJoinLink != ""
                    ){
                        UI::SetCursorPos(vec2(UI::GetWindowSize().x/2.25 - 25, UI::GetWindowSize().y - 25));
                        if (UI::Button(Icons::Kenney::Reload + " Join Server")) TM::JoinServer(g_matchInfo.tmServer.quickJoinLink);
                    }
                }
            }
        }
    }

    void RenderQueueButton() {
        UI::SetCursorPos(vec2((UI::GetWindowSize().x*.5) - (UI::MeasureString(queueButtonMsg).x/2), UI::GetWindowSize().y - 25));

        if (g_selectedMatchmakingType is null) {
            UI::BeginDisabled();
            queueButtonMsg = Icons::Hourglass + " Loading";
            UI::GrayButton(queueButtonMsg);
            UI::EndDisabled();
            return;
        }

#if !FORCE_JOIN_MATCHMAKING
#if SIG_SCHOOL
        if (!Meta::IsSchoolModeWhitelisted()) {
            UI::BeginDisabled();
            queueButtonMsg = Icons::Times + " School Mode enabled";
            UI::RedButton(queueButtonMsg);
            UI::EndDisabled();
            return;
        }
#endif
        if (g_selectedMatchmakingType.isDisabled) {
            UI::BeginDisabled();
            queueButtonMsg = Icons::Times + " Disabled";
            UI::GrayButton(queueButtonMsg);
            UI::EndDisabled();
            return;
        }
        if (g_selectedMatchmakingType.season is null) {
            UI::BeginDisabled();
            queueButtonMsg = Icons::Times + " No season";
            UI::GrayButton(queueButtonMsg);
            UI::EndDisabled();
            return;
        }
        if (!g_selectedMatchmakingType.season.isActive) {
            UI::BeginDisabled();
            queueButtonMsg = Icons::Stop + " Season ended";
            UI::GrayButton(queueButtonMsg);
            UI::EndDisabled();
            return;
        }
#endif
        if (g_activeSquad !is null) {
#if !FORCE_JOIN_MATCHMAKING
            if (!g_selectedMatchmakingType.allowSquad) {
                UI::BeginDisabled();
                queueButtonMsg = Icons::Times + " Squads not allowed";
                UI::GrayButton(queueButtonMsg);
                UI::EndDisabled();
                return;
            }
            if (g_activeSquad.players.Length > g_selectedMatchmakingType.playersPerTeams) {
                UI::BeginDisabled();
                queueButtonMsg = Icons::Times + " Too many players in squad";
                UI::GrayButton(queueButtonMsg);
                UI::EndDisabled();
                return;
            }
#endif
            // Searching state
            if (g_activeSquad.isSearching) {
                queueButtonMsg = Icons::Times + " Unready";
                if (UI::RedButton(queueButtonMsg)) startnew(CoroutineFunc(SquadSetUnready));
                return;
            }

            // Type not set yet (auto-set by owner via MainWindow, waiting for propagation)
            if (g_activeSquad.matchmakingTypeId == -1) {
                bool isOwner = (g_connectedPlayer !is null && g_connectedPlayer.accountId == g_activeSquad.ownerPlayer);
                UI::BeginDisabled();
                queueButtonMsg = isOwner ? (Icons::ArrowUp + " Select a type above") : (Icons::Hourglass + " Waiting for squad host...");
                UI::GrayButton(queueButtonMsg);
                UI::EndDisabled();
                return;
            }

            // Type set, waiting for ready
            bool meReady = (g_connectedPlayer !is null && g_activeSquad.isPlayerReady(g_connectedPlayer.accountId));
            UI::BeginDisabled(isSquadToggleReadyClicked);
            if (!meReady) {
                queueButtonMsg = Icons::Check + " Ready up";
                if (UI::GreenButton(queueButtonMsg)) startnew(CoroutineFunc(SquadSetReady));
            } else {
                queueButtonMsg = Icons::Times + " Unready";
                if (UI::RedButton(queueButtonMsg)) startnew(CoroutineFunc(SquadSetUnready));
            }
            UI::EndDisabled();
        } else {
            if (!g_queueJoin) {
                UI::BeginDisabled(g_isPingingMatchmakingQueue);
                queueButtonMsg = Icons::Play + " Enter queue";
                if (UI::GreenButton(queueButtonMsg)) startnew(CoroutineFunc(JoinQueueAsync));
                UI::EndDisabled();
            }
            if (g_queueJoin) {
                UI::BeginDisabled(isLeaveQueueClicked);
                queueButtonMsg = Icons::Stop + " Leave queue";
                if (UI::RedButton(queueButtonMsg)) startnew(CoroutineFunc(LeaveQueueAsync));
                UI::EndDisabled();
            }
        }
    }

    void SquadSetReady() { SquadToggleReady(true); }
    void SquadSetUnready() { SquadToggleReady(false); }
}