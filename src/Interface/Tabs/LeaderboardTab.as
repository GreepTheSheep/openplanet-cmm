class LeaderboardTab : Tab {
    Net::HttpRequest@ m_leaderboardGetRequest;
    bool isLoading = false;
    bool isError = false;
    string errorMsg;
    array<MatchmakingLeaderboard@> leaderboardEntries;

    bool IsVisible() override {
        if (g_selectedPlayerMatchmakingType is null) return false;
        if (g_selectedMatchmakingType is null) return false;
        return g_selectedPlayerMatchmakingType.matchesPlayed >= g_selectedMatchmakingType.placementMatches;
    }
    string GetLabel() override { return Icons::Kenney::PodiumAlt; }
    string GetTooltip() override { return "Leaderboard"; }
    vec4 GetColor() override { return vec4(0.33f, 0.035f, 0.7f, 1); }

    void StartRequest()
    {
        isLoading = true;

        dictionary params;
        params.Set("matchmakingId", tostring(g_selectedMatchmakingType.id));
        params.Set("aroundPlayer", "true");

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

        @m_leaderboardGetRequest = API::Get(Setting_BaseURL+"/matchmaking/leaderboard"+urlParams);
    }

    void Reload() override {
        leaderboardEntries.RemoveRange(0, leaderboardEntries.Length);
        StartRequest();
    }

    void CheckStartRequest()
    {
        // If there's not already a request and the window is appearing, we start a new request
        if (m_leaderboardGetRequest is null && UI::IsWindowAppearing()) {
            Reload();
        }
    }

    void CheckRequest()
    {
        CheckStartRequest();

        // If there's a request, check if it has finished
        if (m_leaderboardGetRequest !is null && m_leaderboardGetRequest.Finished()) {
            isLoading = false;
            // Parse the response
            string res = m_leaderboardGetRequest.String();
            if (Meta::IsDeveloperMode()) trace("LeaderboardTab::CheckRequest: " + res);
            @m_leaderboardGetRequest = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                isError = true;
                errorMsg = "Error while loading leaderboard";
                Log::Error(errorMsg);
                return;
            }

            if (json.HasKey("error")) {
                int errCode = json["error"]["code"];
                errorMsg = json["error"]["message"];
                if (errCode == 404) return;
                isError = true;
                Log::Error(errorMsg);
                return;
            }

            isError = false;

            for (uint i = 0; i < json["leaderboard"].Length; i++){
                leaderboardEntries.InsertLast(MatchmakingLeaderboard(json["leaderboard"][i]));
            }
        }
    }

    void Render() override {
        CheckRequest();

        if (isLoading) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading...");
            return;
        }

        if (UI::BeginTable("matchmakingLeaderboard", 4, UI::TableFlags(UI::TableFlags::Resizable | UI::TableFlags::NoSavedSettings | UI::TableFlags::SizingStretchProp | UI::TableFlags::ScrollY))) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Rank", UI::TableColumnFlags::WidthFixed, 40);
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Rating", UI::TableColumnFlags::WidthFixed, 100);
            UI::TableSetupColumn("Matches", UI::TableColumnFlags::WidthFixed, 70);
            UI::TableHeadersRow();

            UI::ListClipper clipper(leaderboardEntries.Length);
            while(clipper.Step()) {
                for(int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    UI::PushID("matchmakingLeaderboard"+i);
                    UI::TableNextRow();

                    UI::TableSetColumnIndex(0);
                    UI::Text(tostring(leaderboardEntries[i].rank));

                    UI::TableSetColumnIndex(1);
                    UI::Text(leaderboardEntries[i].displayName);

                    UI::TableSetColumnIndex(2);
                    UI::Text(tostring(leaderboardEntries[i].rating));

                    UI::TableSetColumnIndex(3);
                    UI::Text(tostring(leaderboardEntries[i].matchesPlayed));
                    UI::SetPreviousTooltip(
                        (leaderboardEntries[i].matchesWin > 0 ? tostring(leaderboardEntries[i].matchesWin) + " W" : "") +
                        (leaderboardEntries[i].matchesWin > 0 && leaderboardEntries[i].matchesLoss > 0 ? " | " : "") +
                        (leaderboardEntries[i].matchesLoss > 0 ? tostring(leaderboardEntries[i].matchesLoss) + " L" : "") +
                        (leaderboardEntries[i].matchesLoss > 0 && leaderboardEntries[i].matchesDraw > 0 ? " | " : "") +
                        (leaderboardEntries[i].matchesDraw > 0 ? tostring(leaderboardEntries[i].matchesDraw) + " D" : "")
                    );

                    UI::PopID();
                }
            }

            UI::EndTable();
        }
    }
}