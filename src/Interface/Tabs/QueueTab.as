class QueueTab : Tab {
    bool isError = false;
    string errorMsg;
    string queueButtonMsg;
    bool isSquadToggleReadyClicked = false;
    bool isLeaveQueueClicked = false;

    string GetID() override { return "queue"; }
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
        if (!g_tcpSocket.connected) @g_activeSquad = Squad(res["squad"]);
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
            if (g_tcpSocket is null || (g_tcpSocket !is null && !g_tcpSocket.connected)) {
                UI::PushFont(Fonts::Bold);
                Controls::BeginFrameWarning(Icons::Exclamation + " Cannot connect to the socket");
                UI::PushFont(Fonts::Regular);
                UI::TextWrapped("Real-time updates and notifications cannot be possible");
                UI::PopFont();
                Controls::EndFrame();
                UI::PopFont();
            }
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
            if (isError) {
                UI::Separator();
                UI::Text("\\$f00" + Icons::ExclamationTriangle + " \\$z" + errorMsg);
            }
            RenderSquadView();
            RenderQueueButton();
        } else {
            if (g_matchInfo !is null) {
                UI::Text(g_matchInfo.status);
                if (g_matchInfo.tmServer !is null) {
                    if (g_matchInfo.map !is null) {
                        UI::Text("Map: " + Text::OpenplanetFormatCodes(g_matchInfo.map.Name));
                        UI::Separator();
                    }
                    UI::Columns(g_matchInfo.teams.Length, "QueueTabMatchView", false);
                    for (uint t = 0; t < g_matchInfo.teams.Length; t++) {
                        UI::BeginChild("MatchTeam"+t);
                        UI::Text(Text::OpenplanetFormatCodes("$" + g_matchInfo.teams[t].colorTM + g_matchInfo.teams[t].name));
                        UI::Separator();
                        for (uint p = 0; p < g_matchInfo.teams[t].players.Length; p++) {
                            Player@ player = g_matchInfo.teams[t].players[p];
                            UI::Text("- " + player.displayName);
                            UI::PlayerInfoTooltip(player);
                            if (UI::BeginPopupContextItem("MatchPlayer"+player.id)) {
                                if (player.badges.Length > 0) {
                                    int newLineEvery = 4;
                                    int badgeIndexLine = 0;
                                    for (uint b = 0; b < player.badges.Length; b++) {
                                        UI::PushID("PlayerBadge"+player.badges[b].id);
                                        UI::AlignTextToFramePadding();
                                        UI::BadgeImage(player.badges[b].badge);
                                        UI::PopID();
                                        if (badgeIndexLine == newLineEvery) {
                                            badgeIndexLine = 0;
                                        } else {
                                            UI::SameLine();
                                            badgeIndexLine++;
                                        }
                                    }
                                }
                                UI::EndPopup();
                            }
                            if (player.featuredBadge !is null) {
                                UI::SameLine();
                                UI::BadgeImage(player.featuredBadge);
                            }
                            if (player.group.icon.Length > 0) {
                                UI::SameLine();
                                UI::Text(player.group.iconWithColor);
                                UI::SetPreviousTooltip(player.group.name);
                            }
                            for (uint mt = 0; mt < player.matchmakingTypes.Length; mt++) {
                                if (
                                    player.matchmakingTypes[mt].matchmakingTypeId == g_selectedMatchmakingType.id &&
                                    player.matchmakingTypes[mt].matchesPlayed >= g_selectedMatchmakingType.placementMatches
                                ) {
                                    UI::SameLine();
                                    UI::Text(tostring(player.matchmakingTypes[mt].points));
                                    break;
                                }
                            }
                        }
                        UI::EndChild();
                        UI::NextColumn();
                    }
                    UI::Columns(1);
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

    void RenderSquadView() {
        if (g_activeSquad is null) {
            UI::BeginChild("QueueTabCurrentPlayerView");
            RenderPlayerView(g_connectedPlayer);
            UI::EndChild();
        } else {
            UI::Columns(g_activeSquad.players.Length, "QueueTabPlayersView", false);
            for (uint i = 0; i < g_activeSquad.players.Length; i++) {
                UI::BeginChild("QueueTabPlayerView"+i);
                if (g_activeSquad.players[i].id == g_connectedPlayer.id) RenderPlayerView(g_connectedPlayer); // use full stats for the connected player
                else RenderPlayerView(g_activeSquad.players[i]);
                UI::EndChild();
                UI::NextColumn();
            }
            UI::Columns(1);
        }
    }

    void RenderPlayerView(Player@ player) {
        PlayerMatchmakingType@ selectedPlayerMatchmakingType;
        for (uint p = 0; p < player.matchmakingTypes.Length; p++) {
            if (g_selectedMatchmakingType !is null && player.matchmakingTypes[p].matchmakingTypeId == g_selectedMatchmakingType.id) {
                @selectedPlayerMatchmakingType = player.matchmakingTypes[p];
                break;
            }
        }
        vec2 posTop = UI::GetCursorPos();
        if (selectedPlayerMatchmakingType !is null && selectedPlayerMatchmakingType.matchesPlayed >= g_selectedMatchmakingType.placementMatches) {
            array<float> recentMatchesPoints;
            for (uint rm = 0; rm < selectedPlayerMatchmakingType.recentMatches.Length; rm++) {
                recentMatchesPoints.InsertLast(selectedPlayerMatchmakingType.recentMatches[rm].ratingAfter);
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
                uint index = uint(mousePos.x * selectedPlayerMatchmakingType.recentMatches.Length);
                UI::SetCursorPos(posTop);
                UI::TextDisabled(selectedPlayerMatchmakingType.recentMatches[index].ratingAfter + "pts");
            }
        }

        vec2 playerNameSize = UI::MeasureString(player.displayName + (g_activeSquad !is null && g_activeSquad.isPlayerReady(player.accountId) ? ("  " + Icons::Check) : ""));
        UI::SetCursorPos(vec2(
            (UI::GetWindowSize().x - playerNameSize.x) / 2,
            UI::GetWindowSize().y / 2 - (14 * UI::GetScale())
        ));
        UI::Text(player.displayName);
        if (g_activeSquad !is null && g_activeSquad.isPlayerReady(player.accountId)) {
            UI::SameLine();
            UI::Text("\\$0f0" + Icons::Check);
            UI::SetPreviousTooltip("Ready");
        }
        if (selectedPlayerMatchmakingType !is null && selectedPlayerMatchmakingType.matchesPlayed < g_selectedMatchmakingType.placementMatches) {
            int remaining = g_selectedMatchmakingType.placementMatches - selectedPlayerMatchmakingType.matchesPlayed;
            string matchesLeftString = tostring(remaining) + " matches left to get "+(player.id == g_connectedPlayer.id ? "your":"their")+" ELO";
            if (remaining == 1) matchesLeftString = "Last placement match!";

            UI::SetCursorPos(vec2(
                (UI::GetWindowSize().x - UI::MeasureString(matchesLeftString).x) / 2,
                UI::GetCursorPos().y
            ));
            UI::Text(matchesLeftString);
        }
        UI::SetCursorPos(posTop);
    }

    void RenderQueueButton() {
        UI::SetCursorPos(vec2(
            (UI::GetWindowSize().x - UI::MeasureString(queueButtonMsg).x - 8) / 2,
            UI::GetWindowSize().y - 28
        ));

        UI::BeginChild("QueueTabButtonView");

        if (cmmMainWindow.isLoadingMMType || g_selectedMatchmakingType is null) {
            UI::BeginDisabled();
            queueButtonMsg = Icons::AnimatedHourglass + " Loading";
            UI::GrayButton(queueButtonMsg);
            UI::EndDisabled();
            UI::EndChild();
            return;
        }

#if !CMM_FORCE_JOIN_MATCHMAKING
#if SIG_SCHOOL
        if (!Meta::IsSchoolModeWhitelisted()) {
            UI::BeginDisabled();
            queueButtonMsg = Icons::University + " School Mode enabled";
            UI::RedButton(queueButtonMsg);
            UI::EndDisabled();
            UI::EndChild();
            return;
        }
#endif
        if (g_selectedMatchmakingType.isDisabled) {
            UI::BeginDisabled();
            queueButtonMsg = Icons::TimesCircle + " Disabled";
            UI::GrayButton(queueButtonMsg);
            UI::EndDisabled();
            UI::EndChild();
            return;
        }
        if (g_selectedMatchmakingType.season is null) {
            UI::BeginDisabled();
            queueButtonMsg = Icons::TimesCircle + " No season";
            UI::GrayButton(queueButtonMsg);
            UI::EndDisabled();
            UI::EndChild();
            return;
        }
        if (!g_selectedMatchmakingType.season.isActive) {
            UI::BeginDisabled();
            if (g_selectedMatchmakingType.season.isUpcoming) queueButtonMsg = Icons::ClockO + " Season starts in " + Time::displayTimeLeft(g_selectedMatchmakingType.season.startDateTimestamp);
            else queueButtonMsg = Icons::Stop + " Season ended";
            UI::GrayButton(queueButtonMsg);
            UI::EndDisabled();
            UI::EndChild();
            return;
        }
#endif
        if (g_activeSquad !is null) {
#if !CMM_FORCE_JOIN_MATCHMAKING
            if (!g_selectedMatchmakingType.allowSquad) {
                UI::BeginDisabled();
                queueButtonMsg = Icons::TimesCircle + " Squads not allowed";
                UI::GrayButton(queueButtonMsg);
                UI::EndDisabled();
                UI::EndChild();
                return;
            }
            if (g_activeSquad.players.Length > g_selectedMatchmakingType.playersPerTeams) {
                UI::BeginDisabled();
                queueButtonMsg = Icons::TimesCircle + " Too many players in squad";
                UI::GrayButton(queueButtonMsg);
                UI::EndDisabled();
                UI::EndChild();
                return;
            }
#endif
            // Searching state
            if (g_activeSquad.isSearching) {
                queueButtonMsg = Icons::Times + " Unready";
                if (UI::RedButton(queueButtonMsg)) startnew(CoroutineFunc(SquadSetUnready));
                UI::EndChild();
                return;
            }

            // Type not set yet (auto-set by owner via MainWindow, waiting for propagation)
            if (g_activeSquad.matchmakingTypeId == -1) {
                bool isOwner = (g_connectedPlayer !is null && g_connectedPlayer.accountId == g_activeSquad.ownerPlayer);
                UI::BeginDisabled();
                queueButtonMsg = isOwner ? (Icons::ArrowUp + " Select a type above") : (Icons::AnimatedHourglass + " Waiting for squad host...");
                UI::GrayButton(queueButtonMsg);
                UI::EndDisabled();
                UI::EndChild();
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
        UI::EndChild();
    }

    void SquadSetReady() { SquadToggleReady(true); }
    void SquadSetUnready() { SquadToggleReady(false); }
}