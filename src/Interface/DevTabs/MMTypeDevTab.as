class MMTypeDevTab : Tab {
    Net::HttpRequest@ m_getRequest;
    Net::HttpRequest@ m_getSettingsRequest;
    Net::HttpRequest@ m_getMapPackRequest;
    bool isError = false;
    string errorMsg = "";
    bool isLoading = false;
    MatchmakingType@ selectedType;
    MatchmakingTypeSeasonMapPack@ selectedTypeSeasonMapPack;
    int selectedTypeIndex;
    array<MatchmakingTypeModeSetting@> selectedTypeModeSettings;
    MatchmakingTypeModeSetting@ settingToRemove;
    bool typeDisableEdit;
    string typeNameEdit;
    bool typeAllowSquadEdit;
    string seasonNameEdit;
    int seasonMapPackIdEdit;
    string seasonMapPackSecretEdit;
    bool matchmakingTypeSelectChanged = false;

    string GetLabel() override { return "Matchmaking Type"; }
    bool IsVisible() override { return g_connectedPlayer.hasPermission("edit_mmtype"); }

    void Reload() override {
        selectedTypeModeSettings.RemoveRange(0, selectedTypeModeSettings.Length);
        isLoading = true;

        dictionary params;
        params.Set("id", tostring(selectedType.id));
        params.Set("matchmakingTypeId", tostring(selectedType.id));

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
        @m_getSettingsRequest = API::Get(Setting_BaseURL+"/admin/mmtype/modesettings"+urlParams);
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
            if (Meta::IsDeveloperMode()) trace("MMTypeDevTab::m_getRequest::CheckRequest: " + res);
            @m_getRequest = null;
            auto json = Json::Parse(res);
            @selectedType = MatchmakingType(json);
            typeDisableEdit = selectedType.isDisabled;
            typeNameEdit = selectedType.name;
            typeAllowSquadEdit = selectedType.allowSquad;
            if (selectedType.season !is null) {
                seasonNameEdit = selectedType.season.name;
                @m_getMapPackRequest = API::Get(Setting_BaseURL+"/admin/season/"+selectedType.season.id+"/mappack");
            }
        }
        if (m_getSettingsRequest !is null && m_getSettingsRequest.Finished()) {
            string resSettings = m_getSettingsRequest.String();
            if (Meta::IsDeveloperMode()) trace("MMTypeDevTab::m_getSettingsRequest::CheckRequest: " + resSettings);
            @m_getSettingsRequest = null;
            auto jsonSettings = Json::Parse(resSettings);
            for (uint i = 0; i < jsonSettings["modeSettings"].Length; i++) {
                selectedTypeModeSettings.InsertLast(MatchmakingTypeModeSetting(jsonSettings["modeSettings"][i]));
            }
        }
        if (m_getMapPackRequest !is null && m_getMapPackRequest.Finished()) {
            string resMapPack = m_getMapPackRequest.String();
            if (Meta::IsDeveloperMode()) trace("MMTypeDevTab::m_getMapPackRequest::CheckRequest: " + resMapPack);
            @m_getMapPackRequest = null;
            @selectedTypeSeasonMapPack = MatchmakingTypeSeasonMapPack(Json::Parse(resMapPack));
            seasonMapPackIdEdit = selectedTypeSeasonMapPack.mxMapPackId;
            seasonMapPackSecretEdit = selectedTypeSeasonMapPack.mxMapPackSecret;
        }
    }

    void SelectMatchmakingType(MatchmakingType@ matchmakingType) {
        @selectedType = matchmakingType;
        selectedTypeIndex = g_matchmakingTypes.FindByRef(matchmakingType);
        Reload();
    }

    void PostMMType() {
        Json::Value@ postJson = Json::Object();
        postJson["id"] = selectedType.id;
        postJson["disabled"] = typeDisableEdit;
        postJson["name"] = typeNameEdit;
        postJson["allowSquad"] = typeAllowSquadEdit;

        Json::Value@ resPost = API::PostAsync(Setting_BaseURL+"/admin/mmtype", Json::Write(postJson));
        g_matchmakingTypes.RemoveAt(selectedTypeIndex);
        g_matchmakingTypes.InsertAt(selectedTypeIndex, MatchmakingType(resPost));
    }

    void PostEndSeason() {
        Json::Value@ postJson = Json::Object();
        postJson["seasonId"] = selectedType.season.id;

        Json::Value@ resPost = API::PostAsync(Setting_BaseURL+"/admin/season/end", Json::Write(postJson));
        @selectedType.season = MatchmakingTypeSeason(resPost["season"]);
        g_matchmakingTypes.RemoveAt(selectedTypeIndex);
        g_matchmakingTypes.InsertAt(selectedTypeIndex, selectedType);
    }

    void PostNewSeason() {
        Json::Value@ postJson = Json::Object();
        postJson["matchmakingTypeId"] = selectedType.id;
        postJson["name"] = seasonNameEdit;
        postJson["mxMapPackId"] = seasonMapPackIdEdit;
        postJson["mxMapPackSecret"] = seasonMapPackSecretEdit;

        Json::Value@ resPost = API::PostAsync(Setting_BaseURL+"/admin/season", Json::Write(postJson));
        @selectedType.season = MatchmakingTypeSeason(resPost["season"]);
        g_matchmakingTypes.RemoveAt(selectedTypeIndex);
        g_matchmakingTypes.InsertAt(selectedTypeIndex, selectedType);
    }

    void PostMMTypeModeSettings() {
        Json::Value@ postJson = Json::Object();
        postJson["matchmakingTypeId"] = selectedType.id;
        postJson["modeSettings"] = Json::Array();

        for (uint i = 0; i < selectedTypeModeSettings.Length; i++) {
            postJson["modeSettings"].Add(selectedTypeModeSettings[i].ToJson());
        }

        Json::Value@ resPost = API::PostAsync(Setting_BaseURL+"/admin/mmtype/modesettings", Json::Write(postJson));

        selectedTypeModeSettings.RemoveRange(0, selectedTypeModeSettings.Length);
        for (uint i = 0; i < resPost["modeSettings"].Length; i++) {
            selectedTypeModeSettings.InsertLast(MatchmakingTypeModeSetting(resPost["modeSettings"][i]));
        }
    }

    void RemoveSetting() {
        selectedTypeModeSettings.RemoveAt(selectedTypeModeSettings.FindByRef(settingToRemove));
        @settingToRemove = null;
    }

    void AddNewSetting() {
        // Create new JSON object then transform to class
        Json::Value@ setting = Json::Object();
        setting["id"] = 0;
        setting["matchmakingTypeId"] = selectedType.id;
        setting["settingName"] = "";
        setting["settingType"] = "";
        setting["settingValue"] = "";
        selectedTypeModeSettings.InsertLast(MatchmakingTypeModeSetting(setting));
    }

    void SyncSeasonMapPackInfos() {
        Json::Value@ postJson = Json::Object();
        postJson["mxMapPackId"] = selectedTypeSeasonMapPack.mxMapPackId;
        Json::Value@ resPost = API::PostAsync(Setting_BaseURL+"/admin/mappack/sync", Json::Write(postJson));
        selectedTypeSeasonMapPack.maps.RemoveRange(0, selectedTypeSeasonMapPack.maps.Length);
        for (uint i = 0; i < resPost["maps"].Length; i++) {
            selectedTypeSeasonMapPack.maps.InsertLast(MatchmakingTypeSeasonMap(resPost["maps"][i]));
        }
    }

    void PostSeasonMapPackInfos() {
        if (selectedType.season is null) {
            Log::Error("Season is null, please check the active season before.");
            return;
        }
        Json::Value@ postJson = Json::Object();
        postJson["mxMapPackId"] = seasonMapPackIdEdit;
        postJson["mxMapPackSecret"] = seasonMapPackSecretEdit;
        Json::Value@ resPost = API::PostAsync(Setting_BaseURL+"/admin/season/"+selectedType.season.id+"/mappack", Json::Write(postJson));
        selectedTypeSeasonMapPack.mxMapPackId = seasonMapPackIdEdit;
        selectedTypeSeasonMapPack.mxMapPackSecret = seasonMapPackSecretEdit;
    }

    void Render() override
    {
        CheckRequest();

        if (isError) {
            UI::Text("\\$f00" + Icons::ExclamationTriangle + " \\$z" + errorMsg);
            return;
        }

        UI::AlignTextToFramePadding();
        UI::Text("Select Type to view / edit");
        UI::SameLine();
        UI::SetNextItemWidth(200);
        if (UI::BeginCombo("##MatchmakingTypeSelect", selectedType.name)) {
            for (uint i = 0; i < g_matchmakingTypes.Length; i++) {
                matchmakingTypeSelectChanged = UI::Selectable(g_matchmakingTypes[i].name+"##"+g_matchmakingTypes[i].id, matchmakingTypeSelectChanged);
                if (matchmakingTypeSelectChanged) SelectMatchmakingType(g_matchmakingTypes[i]);
            }
            UI::EndCombo();
        }
        UI::SameLine();
        UI::TextDisabled("Identifier: " + selectedType.id);
        UI::SameLine();
        UI::Text(Icons::Refresh);
        UI::SetPreviousTooltip("Reload this type");
        if (UI::IsItemClicked()) Reload();

        UI::Separator();
        float width = UI::GetWindowSize().x*0.35;
        float widthRight = UI::GetWindowSize().x-width;
        vec2 posTop = UI::GetCursorPos();

        UI::BeginChild("Edit Type Infos", vec2(width, 185));

        typeDisableEdit = UI::Checkbox("Disable##typeDisableEdit", typeDisableEdit);
        typeAllowSquadEdit = UI::Checkbox("Allow Squads##typeAllowSquadEdit", typeAllowSquadEdit);
        UI::SetNextItemWidth(250);
        typeNameEdit = UI::InputText("Set name##typeNameEdit", typeNameEdit);

        if (UI::GreenButton(Icons::FloppyO + " Save")) startnew(CoroutineFunc(PostMMType));

        UI::EndChild();

        vec2 posBottom = UI::GetCursorPos();

        UI::SetCursorPos(posTop + vec2(width + 8, 0));
        UI::BeginChild("Season", vec2(widthRight - 8, 185));

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
        } else UI::Text("\\$f00Active season is null, check server");

        if (selectedType.season is null || !selectedType.season.isActive) {
            UI::NewLine();
            UI::Text("Create new season");
            UI::SetNextItemWidth(250);
            seasonNameEdit = UI::InputText("Set name##seasonNameEdit", seasonNameEdit);
            UI::SetNextItemWidth(250);
            seasonMapPackIdEdit = UI::InputInt("Set Map Pack ID##seasonMapPackIdEdit", seasonMapPackIdEdit);
            UI::SetNextItemWidth(250);
            seasonMapPackSecretEdit = UI::InputText("Set Map Pack Secret (API key, if any)##seasonMapPackSecretEdit", seasonMapPackSecretEdit, UI::InputTextFlags::CharsNoBlank);
            if (UI::GreenButton("New season")) startnew(CoroutineFunc(PostNewSeason));
        }

        UI::EndChild();

        posTop = posBottom;
        UI::SetCursorPos(posTop);

        UI::Separator();

        width = UI::GetWindowSize().x*0.45;
        widthRight = UI::GetWindowSize().x-width;
        posTop = UI::GetCursorPos();

        UI::BeginChild("Mappack", vec2(width,0));

        if (selectedTypeSeasonMapPack !is null) {
            UI::AlignTextToFramePadding();
            UI::Text("Map Pack ID: " + selectedTypeSeasonMapPack.mxMapPackId);
            UI::SameLine();
            if (UI::Button(Icons::ManiaExchange)) OpenBrowserURL("https://trackmania.exchange/mappackshow/"+selectedTypeSeasonMapPack.mxMapPackId + (selectedTypeSeasonMapPack.mxMapPackSecret.Length > 0 ? "/"+selectedTypeSeasonMapPack.mxMapPackSecret : ""));
        } else UI::Text("Map Pack is null.");

        UI::SetNextItemWidth(250);
        seasonMapPackIdEdit = UI::InputInt("Set Map Pack ID##seasonMapPackIdEdit", seasonMapPackIdEdit);
        UI::SetNextItemWidth(250);
        seasonMapPackSecretEdit = UI::InputText("Set Map Pack Secret (API key, if any)##seasonMapPackSecretEdit", seasonMapPackSecretEdit, UI::InputTextFlags::CharsNoBlank);
        if (UI::GreenButton(Icons::FloppyO + " Save")) startnew(CoroutineFunc(PostSeasonMapPackInfos));

        if (selectedTypeSeasonMapPack !is null) {
            UI::Separator();
            if (selectedTypeSeasonMapPack.maps.Length == 0) {
                UI::Text("Cached maps for this season are empty, try to sync maps");
                if (UI::OrangeButton(Icons::Refresh + " Sync maps to server cache")) startnew(CoroutineFunc(SyncSeasonMapPackInfos));
            } else {
                UI::AlignTextToFramePadding();
                UI::Text("Cached maps for this season:");
                UI::SameLine();
                if (UI::OrangeButton(Icons::Refresh + " Sync maps to server cache")) startnew(CoroutineFunc(SyncSeasonMapPackInfos));
                if (UI::BeginTable("mmSeasonMapPack", 3, UI::TableFlags(UI::TableFlags::Resizable | UI::TableFlags::NoSavedSettings | UI::TableFlags::SizingStretchProp | UI::TableFlags::ScrollY))) {
                    UI::TableSetupScrollFreeze(0, 1);
                    UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("MX Uploader", UI::TableColumnFlags::WidthFixed, 100);
                    UI::TableSetupColumn("Downloaded to server", UI::TableColumnFlags::WidthFixed, 100);
                    UI::TableHeadersRow();

                    UI::ListClipper clipper(selectedTypeSeasonMapPack.maps.Length);
                    while(clipper.Step()) {
                        for(int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                            UI::PushID("mmSeasonMapPack"+i);
                            UI::TableNextRow();

                            UI::TableSetColumnIndex(0);
                            UI::Text(Text::OpenplanetFormatCodes(selectedTypeSeasonMapPack.maps[i].gbxMapName));
                            if (UI::IsItemClicked()) OpenBrowserURL("https://trackmania.exchange/mapshow/"+selectedTypeSeasonMapPack.maps[i].mxMapId + "?mappackid=" + selectedTypeSeasonMapPack.mxMapPackId);

                            UI::TableSetColumnIndex(1);
                            UI::Text(selectedTypeSeasonMapPack.maps[i].uploaderName);

                            UI::TableSetColumnIndex(2);
                            UI::Text(selectedTypeSeasonMapPack.maps[i].downloadedAt.Length > 0 ? Icons::Check : Icons::Times);

                            UI::PopID();
                        }
                    }

                    UI::EndTable();
                }
            }
        }

        UI::EndChild();

        UI::SetCursorPos(posTop + vec2(width + 8, 0));
        UI::BeginChild("ModeSettings", vec2(widthRight - 8, 0));
        UI::AlignTextToFramePadding();
        UI::Text("ModeSettings");
        UI::SameLine();
        if (UI::Button(Icons::Plus)) startnew(CoroutineFunc(AddNewSetting));
        UI::SameLine();
        if (UI::GreenButton(Icons::FloppyO + " Update settings")) startnew(CoroutineFunc(PostMMTypeModeSettings));

        if (UI::BeginTable("mmTypeModeSettings", 5, UI::TableFlags(UI::TableFlags::Resizable | UI::TableFlags::NoSavedSettings | UI::TableFlags::SizingStretchProp | UI::TableFlags::ScrollY))) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("ID", UI::TableColumnFlags::WidthFixed, 20);
            UI::TableSetupColumn("Setting Name", UI::TableColumnFlags::WidthFixed, 260);
            UI::TableSetupColumn("Setting Type", UI::TableColumnFlags::WidthFixed, 110);
            UI::TableSetupColumn("Setting Value", UI::TableColumnFlags::WidthFixed, 260);
            UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthStretch);
            UI::TableHeadersRow();

            UI::ListClipper clipper(selectedTypeModeSettings.Length);
            while(clipper.Step()) {
                for(int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
                {
                    UI::PushID("mmTypeModeSettings"+i);
                    UI::TableNextRow();

                    UI::TableSetColumnIndex(0);
                    UI::Text(selectedTypeModeSettings[i].id == 0 ? Icons::PlusCircle : tostring(selectedTypeModeSettings[i].id));

                    UI::TableSetColumnIndex(1);
                    UI::SetNextItemWidth(260 - 8);
                    selectedTypeModeSettings[i].settingName = UI::InputText("##settingNameEdit"+i, selectedTypeModeSettings[i].settingName);

                    UI::TableSetColumnIndex(2);
                    UI::SetNextItemWidth(110 - 8);
                    selectedTypeModeSettings[i].settingType = UI::InputText("##settingTypeEdit"+i, selectedTypeModeSettings[i].settingType);

                    UI::TableSetColumnIndex(3);
                    UI::SetNextItemWidth(260 - 8);
                    selectedTypeModeSettings[i].settingValue = UI::InputText("##settingValueEdit"+i, selectedTypeModeSettings[i].settingValue);

                    UI::TableSetColumnIndex(4);
                    if (UI::RedButton(Icons::TrashO)) {
                        @settingToRemove = selectedTypeModeSettings[i];
                        startnew(CoroutineFunc(RemoveSetting));
                    }
                    UI::SetPreviousTooltip("Remove this setting");

                    UI::PopID();
                }
            }

            UI::EndTable();
        }

        UI::EndChild();
    }
}