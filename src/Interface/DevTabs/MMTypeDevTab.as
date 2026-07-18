class MMTypeDevTab : Tab {
    Net::HttpRequest@ m_getRequest;
    bool isError = false;
    string errorMsg = "";
    bool isLoading = false;
    MatchmakingType@ selectedType;
    bool typeDisableEdit;
    string typeNameEdit;
    string seasonNameEdit;
    bool matchmakingTypeSelectChanged = false;

    string GetLabel() override { return "Matchmaking Type"; }
    bool IsVisible() override { return g_connectedPlayer.hasPermission("edit_mmtype"); }

    void Reload() override {
        isLoading = true;

        dictionary params;
        params.Set("id", tostring(selectedType.id));

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

        @m_getRequest = API::Get(Setting_BaseURL+"/matchmaking/type/status"+urlParams);
    }

    void CheckStartRequest()
    {
        if (m_getRequest is null && UI::IsWindowAppearing()) {
            if (selectedType is null) SelectMatchmakingType(g_matchmakingTypes[0]);
            else Reload();
        }
    }

    void CheckRequest()
    {
        CheckStartRequest();

        if (m_getRequest !is null && m_getRequest.Finished()) {
            isLoading = false;
            // Parse the response
            string res = m_getRequest.String();
            if (Meta::IsDeveloperMode()) trace("MMTypeDevTab::CheckRequest: " + res);
            @m_getRequest = null;
            auto json = Json::Parse(res);
            MatchmakingType@ resType = MatchmakingType(json);
            typeDisableEdit = resType.isDisabled;
            typeNameEdit = resType.name;
            seasonNameEdit = resType.season.name;
            @selectedType = resType;
        }
    }

    void SelectMatchmakingType(MatchmakingType@ matchmakingType) {
        @selectedType = matchmakingType;
        Reload();
    }

    void PostMMType() {
        int index = g_matchmakingTypes.FindByRef(selectedType);

        Json::Value@ postJson = Json::Object();
        postJson["id"] = selectedType.id;
        postJson["disabled"] = typeDisableEdit;
        postJson["name"] = typeNameEdit;

        Json::Value@ resPost = API::PostAsync(Setting_BaseURL+"/admin/mmtype", Json::Write(postJson));
        MatchmakingType@ resType = MatchmakingType(resPost);
        g_matchmakingTypes.RemoveAt(index);
        g_matchmakingTypes.InsertAt(index, resType);
        @selectedType = resType;
    }

    void PostEndSeason() {
        int index = g_matchmakingTypes.FindByRef(selectedType);

        Json::Value@ postJson = Json::Object();
        postJson["seasonId"] = selectedType.season.id;

        Json::Value@ resPost = API::PostAsync(Setting_BaseURL+"/admin/season/end", Json::Write(postJson));
        @selectedType.season = MatchmakingTypeSeason(resPost["season"]);
        g_matchmakingTypes.RemoveAt(index);
        g_matchmakingTypes.InsertAt(index, selectedType);
    }

    void PostNewSeason() {
        int index = g_matchmakingTypes.FindByRef(selectedType);

        Json::Value@ postJson = Json::Object();
        postJson["matchmakingTypeId"] = selectedType.id;
        postJson["name"] = seasonNameEdit;

        Json::Value@ resPost = API::PostAsync(Setting_BaseURL+"/admin/season", Json::Write(postJson));
        @selectedType.season = MatchmakingTypeSeason(resPost["season"]);
        g_matchmakingTypes.RemoveAt(index);
        g_matchmakingTypes.InsertAt(index, selectedType);
    }

    void Render() override
    {
        CheckRequest();

        if (isError) {
            UI::Text("\\$f00" + Icons::ExclamationTriangle + " \\$z" + errorMsg);
            return;
        }

        UI::Text("Select Type to view / edit");
        UI::SameLine();
        UI::Text(Icons::Refresh);
        UI::SetPreviousTooltip("Reload types");
        if (UI::IsItemClicked()) Reload();
        UI::SetNextItemWidth(200);
        if (UI::BeginCombo("##MatchmakingTypeSelect", selectedType.name)) {
            for (uint i = 0; i < g_matchmakingTypes.Length; i++) {
                matchmakingTypeSelectChanged = UI::Selectable(g_matchmakingTypes[i].name+"##"+g_matchmakingTypes[i].id, matchmakingTypeSelectChanged);
                if (matchmakingTypeSelectChanged) SelectMatchmakingType(g_matchmakingTypes[i]);
            }
            UI::EndCombo();
        }
        UI::TextDisabled("Identifier: " + selectedType.id);

        UI::Separator();

        typeDisableEdit = UI::Checkbox("Disable##typeDisableEdit", typeDisableEdit);
        typeNameEdit = UI::InputText("Set name##typeNameEdit", typeNameEdit);

        if (UI::GreenButton("Save")) startnew(CoroutineFunc(PostMMType));

        UI::Separator();

        if (selectedType.season !is null) {
            UI::Text((selectedType.season.isActive ? "\\$0f0Active\\$z " : "\\$949Last\\$z ") + "Season info:");
            UI::Text("Season #" + selectedType.season.number);
            UI::SameLine();
            UI::Text((selectedType.season.isActive ? "\\$0f0" : "\\$949") + selectedType.season.name);
            UI::SameLine();
            UI::TextDisabled("(ID: " + selectedType.season.id + ")");
            UI::Text("Start date: " + (selectedType.season.startDateTimestamp != 0 ? Time::FormatString("%c", selectedType.season.startDateTimestamp) : "undefined"));
            UI::Text("End date: " + (selectedType.season.endDateTimestamp != 0 ? Time::FormatString("%c", selectedType.season.endDateTimestamp) : "undefined"));

            if (selectedType.season.isActive && UI::RedButton("End this season")) startnew(CoroutineFunc(PostEndSeason));

            if (!selectedType.season.isActive) {
                UI::NewLine();
                UI::Text("Create new season");
                seasonNameEdit = UI::InputText("Set name##seasonNameEdit", seasonNameEdit);
                if (UI::GreenButton("New season")) startnew(CoroutineFunc(PostNewSeason));
            }
        } else UI::Text("\\$f00Can't get season info, check server");

    }
}