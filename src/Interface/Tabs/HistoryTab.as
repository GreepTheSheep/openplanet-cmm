class HistoryTab : Tab {
    Net::HttpRequest@ m_historyGetRequest;
    bool isLoading = false;
    bool isError = false;
    string errorMsg;
    int lastMatchmakingTypeId;
    array<MatchHistory@> historyMatches;

    string GetID() override { return "history"; }
    bool IsVisible() override {
        if (g_selectedMatchmakingType is null) return false;
        if (g_selectedMatchmakingType.season is null) return false;
        return true;
    }
    string GetLabel() override { return Icons::History; }
    string GetTooltip() override { return "History"; }
    vec4 GetColor() override { return vec4(0.11f, 0.4f, 0.78f, 1); }

    void StartRequest()
    {
        isLoading = true;

        dictionary params;
        params.Set("matchmakingId", tostring(g_selectedMatchmakingType.id));

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

        @m_historyGetRequest = API::Get(Setting_BaseURL+"/matchmaking/history"+urlParams);
    }

    void Reload() override {
        historyMatches.RemoveRange(0, historyMatches.Length);
        lastMatchmakingTypeId = g_selectedMatchmakingType.id;
        StartRequest();
    }

    void CheckStartRequest()
    {
        // If there's not already a request and the window is appearing, we start a new request
        if (m_historyGetRequest is null && UI::IsWindowAppearing()) Reload();

        // Reload page if the matchmaking type has been changed
        if (lastMatchmakingTypeId > 0 && lastMatchmakingTypeId != g_selectedMatchmakingType.id) Reload();
    }

    void CheckRequest()
    {
        CheckStartRequest();

        // If there's a request, check if it has finished
        if (m_historyGetRequest !is null && m_historyGetRequest.Finished()) {
            isLoading = false;
            // Parse the response
            string res = m_historyGetRequest.String();
            if (Meta::IsDeveloperMode()) trace("HistoryTab::CheckRequest: " + res);
            @m_historyGetRequest = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                isError = true;
                errorMsg = "Error while loading history";
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

            for (uint i = 0; i < json["history"].Length; i++){
                historyMatches.InsertLast(MatchHistory(json["history"][i]));
            }
            isError = false;
            errorMsg = "";
        }
    }

    void Render() override {
        CheckRequest();

        if (isLoading) {
            UI::Text(Icons::AnimatedHourglass + " Loading...");
            return;
        }

        if (historyMatches.Length == 0) {
            UI::Text("No matches have been recorded for this matchmaking on your account");
            return;
        }

        if (UI::BeginTable("matchHistory", 3, UI::TableFlags(UI::TableFlags::Resizable | UI::TableFlags::NoSavedSettings | UI::TableFlags::SizingStretchProp | UI::TableFlags::ScrollY))) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Result", UI::TableColumnFlags::WidthFixed, 50);
            UI::TableSetupColumn("Date", UI::TableColumnFlags::WidthFixed, 200);
            UI::TableSetupColumn("Rating", UI::TableColumnFlags::WidthStretch);
            UI::TableHeadersRow();

            UI::ListClipper clipper(historyMatches.Length);
            while(clipper.Step()) {
                for(int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    UI::PushID("matchHistory"+i);
                    UI::TableNextRow();

                    UI::TableSetColumnIndex(0);
                    if (historyMatches[i].matchResult == "win")
                        UI::Text("\\$4a0" + Icons::Trophy);
                    else
                        UI::Text("\\$a40" + Icons::Times);

                    UI::TableSetColumnIndex(1);
                    UI::Text(historyMatches[i].calculatedAtTimestamp != 0 ? Time::FormatString("%c", historyMatches[i].calculatedAtTimestamp) : historyMatches[i].calculatedAt);

                    UI::TableSetColumnIndex(2);
                    if (historyMatches[i].isPlacement) {
                        UI::Text("Placement match");
                    } else {
                        UI::Text(tostring(historyMatches[i].ratingAfter));
                        UI::SameLine();
                        if (historyMatches[i].delta > 0)
                            UI::Text("\\$0f0(+"+historyMatches[i].delta+")");
                        else
                            UI::Text("\\$f00(-"+historyMatches[i].delta+")");
                    }

                    UI::PopID();
                }
            }

            UI::EndTable();
        }
    }
}