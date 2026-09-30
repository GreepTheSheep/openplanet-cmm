class MainWindow : Window {
    Net::HttpRequest@ m_getMeRequest;
    Net::HttpRequest@ m_getMMTypeRequest;
    bool isError = false;
    string errorMsg = "";
    bool isLoading = false;
    bool isLoadingMMType = true;
    bool matchmakingTypeSelectChanged = false;

    MainWindow(){
        AddTab(QueueTab());
        AddTab(SquadTab());
        AddTab(UserTab());
        AddTab(HistoryTab());
        AddTab(LeaderboardTab());
        AddTab(InfoTab());
        AddTab(SettingTab());
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
            if (Meta::IsDeveloperMode()) trace("MainWindow::CheckRequest(User): " + res);
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

            @g_connectedPlayer = Player(json);
            isError = false;
            errorMsg = "";
            if (g_selectedMatchmakingType is null) {
                if (Setting_LastSelectedMatchmakingIndex > g_matchmakingTypes.Length - 1) Setting_LastSelectedMatchmakingIndex = 0;
                SelectMatchmakingType(g_matchmakingTypes[Setting_LastSelectedMatchmakingIndex]);
            }
        }
    }

    string GetWindowId() override { return PLUGIN_NAME_SHORT+"MainWindow"; }

    void RenderHeader() override {
        CheckRequest();
        CheckRequestMMType();

        if (isLoading) {
            UI::Text(Icons::AnimatedHourglass + " Loading...");
            return;
        }

        if (isError) {
            UI::Text("\\$f00" + Icons::ExclamationTriangle + " \\$z" + errorMsg);
            return;
        }

        vec2 BasePos = UI::GetCursorPos();
        if (isLoadingMMType) UI::Text(Icons::AnimatedHourglass + " Loading...");
        else {
            // Add tooltip if the season will have a end date
            string seasonTooltipText = "";
            if (g_selectedMatchmakingType.season !is null) {
                if (g_selectedMatchmakingType.season.endDateTimestamp != 0) {
                    if (g_selectedMatchmakingType.season.isActive) {
                        int64 timestampLeft = g_selectedMatchmakingType.season.endDateTimestamp - Time::Stamp;
                        Time::Info timeLeft = Time::Parse(timestampLeft);
                        string timeLeftString = "";
                        if (timeLeft.Month > 1) timeLeftString += tostring(timeLeft.Month) + " months, ";
                        if (timeLeft.Day > 1) timeLeftString += tostring(timeLeft.Day) + " days and ";
                        timeLeftString += Time::FormatString("%T", timestampLeft);
                        seasonTooltipText += "This season will end in " + timeLeftString;
                    } else seasonTooltipText += "This season has ended on " + Time::FormatString("%c", g_selectedMatchmakingType.season.endDateTimestamp);
                }
                UI::Text((g_selectedMatchmakingType.season.isActive ? "" : "\\$555") + g_selectedMatchmakingType.season.name + (seasonTooltipText.Length > 0 ? " " + Icons::InfoCircle : ""));
                if (seasonTooltipText.Length > 0) UI::SetPreviousTooltip(seasonTooltipText);
            } else UI::Text(g_selectedMatchmakingType.name);
        }
        if (isLoadingMMType) UI::Text(Icons::AnimatedHourglass + " Loading...");
        else {
            if (g_selectedMatchmakingType.season !is null) {
                if (g_selectedMatchmakingType.season.isActive) {
                    // Don't show points until player has done placement matches
                    if (g_selectedPlayerMatchmakingType.matchesPlayed < g_selectedMatchmakingType.placementMatches) {
                        int remaining = g_selectedMatchmakingType.placementMatches - g_selectedPlayerMatchmakingType.matchesPlayed;
                        if (remaining == 1) UI::Text(Icons::ArrowCircleORight + " Last placement match!");
                        else UI::Text(Icons::ArrowCircleORight + " " + tostring(remaining) + " matches left to get your ELO");
                    } else {
                        UI::Text("\\$900" + Icons::DotCircleO + " " + g_selectedPlayerMatchmakingType.points);
                    }
                } else {
                    UI::Text("\\$949"+ Icons::Stop +" Season ended");
                }
            } else UI::Text("\\$f00" + Icons::Times + " \\$zNo active or last season.");
        }
        vec2 BottomPos = UI::GetCursorPos();

        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 215, BasePos.y + 12));

        UI::BeginDisabled(isLoadingMMType || g_queueJoin || g_inMatch || (g_activeSquad !is null && g_connectedPlayer !is null && g_connectedPlayer.accountId != g_activeSquad.ownerPlayer));
        UI::SetNextItemWidth(200);
        if (isLoadingMMType) {
            if (UI::BeginCombo("##MatchmakingTypeSelect", "Loading...")) UI::EndCombo();
        } else {
            if (UI::BeginCombo("##MatchmakingTypeSelect", g_selectedMatchmakingType.name)) {
                for (uint i = 0; i < g_matchmakingTypes.Length; i++) {
                    if (!g_matchmakingTypes[i].allowSquad && g_activeSquad !is null) continue; // Skips matchmakings that are not squad allowed if we're on a squad
                    matchmakingTypeSelectChanged = UI::Selectable(g_matchmakingTypes[i].name+"##"+g_matchmakingTypes[i].id, matchmakingTypeSelectChanged);
                    if (matchmakingTypeSelectChanged) {
                        SelectMatchmakingType(g_matchmakingTypes[i]);
                        Setting_LastSelectedMatchmakingIndex = i;
                    }
                }
                if (g_activeSquad !is null && g_connectedPlayer !is null && g_connectedPlayer.accountId != g_activeSquad.ownerPlayer)
                    UI::SetPreviousTooltip("Only the squad host can change this");
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
            UI::Text(Text::OpenplanetFormatCodes(g_userNotice.icon));
            if (UI::IsItemHovered()) {
                UI::BeginTooltip();
                UI::PushFont(Fonts::Header);
                UI::Text(Text::OpenplanetFormatCodes(g_userNotice.icon) + "\\$z   " + g_userNotice.title);
                UI::PopFont();
                UI::Markdown(g_userNotice.description);
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
            if (g_serverInfo !is null) {
                UI::Text(Icons::Users + " " + g_serverInfo.connectedPlayers);
                UI::SetPreviousTooltip("Number of players connected into " + PLUGIN_NAME_SHORT);
            }
        } else {
            UI::Text(Icons::BlinkingUser + " " + g_queuePlayersCount);
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
        UI::SetCursorPos(vec2(UI::GetWindowSize().x-UI::MeasureString(versionString).x-10, posOrig.y));
        UI::Text(versionString);
        if (UI::IsItemClicked()) {
            string report = CMMBuildInfo::CreateBuildReportText();
            Log::Log(report);
            IO::SetClipboard(report);
            UI::ShowNotification(Icons::Clipboard + " Build Info copied to clipboard", 2000);
        }
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
            // Parse the response
            string res = m_getMMTypeRequest.String();
            if (Meta::IsDeveloperMode()) trace("HomePageTab::CheckRequest(MMType): " + res);
            @m_getMMTypeRequest = null;
            auto json = Json::Parse(res);
            MatchmakingType@ resType = MatchmakingType(json);
            @g_selectedMatchmakingType = resType;

            for (uint p = 0; p < g_connectedPlayer.matchmakingTypes.Length; p++) {
                if (g_connectedPlayer.matchmakingTypes[p].matchmakingTypeId == g_selectedMatchmakingType.id) {
                    @g_selectedPlayerMatchmakingType = g_connectedPlayer.matchmakingTypes[p];
                    break;
                }
            }

            // Auto-set the squad's matchmaking type when the owner changes the selected type
            if (g_activeSquad !is null && g_connectedPlayer.accountId == g_activeSquad.ownerPlayer && !g_activeSquad.isSearching && g_selectedMatchmakingType.allowSquad && g_activeSquad.matchmakingTypeId != g_selectedMatchmakingType.id) {
                g_activeSquad.matchmakingTypeId = g_selectedMatchmakingType.id;
                startnew(Squad::setMatchmakingType);
            }

            isLoadingMMType = false;
        }
    }
}