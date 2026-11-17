class MMTypeDevTab : Tab {
    Net::HttpRequest@ m_getRequest;
    Net::HttpRequest@ m_getSettingsRequest;
    Net::HttpRequest@ m_getMapPackRequest;
    Net::HttpRequest@ m_getNextSeasonRequest;
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

    int seasonToEdit;
    bool seasonToEditInProgress = false;
    bool seasonToEditCompleted = false;
    bool useNextSeasonOnEdit = false;
    uint seasonNumberEdit;
    string seasonNameEdit;
    Time::Info seasonStartDateEdit = Time::ParseUTC(Time::Stamp);
    bool seasonEndDateEnable = false;
    Time::Info seasonEndDateEdit = Time::ParseUTC(Time::Stamp);
    int seasonMapPackIdEdit;
    string seasonMapPackSecretEdit;
    uint nextSeasonNumberEdit;
    string nextSeasonNameEdit;
    Time::Info nextSeasonStartDateEdit = Time::ParseUTC(Time::Stamp);
    bool nextSeasonEndDateEnable = false;
    Time::Info nextSeasonEndDateEdit = Time::ParseUTC(Time::Stamp);
    int nextSeasonMapPackIdEdit;
    string nextSeasonMapPackSecretEdit;

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

            if (json.GetType() == Json::Type::Null) {
                isError = true;
                errorMsg = "Error while loading matchmaking type";
                Log::Error(errorMsg);
                return;
            }

            if (json.HasKey("error")) {
                isError = true;
                errorMsg = json["error"]["message"];
                Log::Error(errorMsg);
                return;
            }

            @selectedType = MatchmakingType(json);
            typeDisableEdit = selectedType.isDisabled;
            typeNameEdit = selectedType.name;
            typeAllowSquadEdit = selectedType.allowSquad;
            isError = false;
            errorMsg = "";
            if (selectedType.season !is null) {
                seasonNumberEdit = selectedType.season.number;
                seasonNameEdit = selectedType.season.name;
                seasonStartDateEdit = Time::ParseUTC(selectedType.season.startDateTimestamp);
                seasonEndDateEnable = selectedType.season.endDateTimestamp != 0;
                if (seasonEndDateEnable) seasonEndDateEdit = Time::ParseUTC(selectedType.season.endDateTimestamp);
                @m_getMapPackRequest = API::Get(Setting_BaseURL+"/admin/season/"+selectedType.season.id+"/mappack");
            }
            @m_getNextSeasonRequest = API::Get(Setting_BaseURL+"/admin/season/next?matchmakingTypeId="+selectedType.id);
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
        if (m_getNextSeasonRequest !is null && m_getNextSeasonRequest.Finished()) {
            string resNextSeason = m_getNextSeasonRequest.String();
            if (Meta::IsDeveloperMode()) trace("MMTypeDevTab::m_getNextSeasonRequest::CheckRequest: " + resNextSeason);
            @m_getNextSeasonRequest = null;
            auto jsonNextSeason = Json::Parse(resNextSeason);
            if (jsonNextSeason.HasKey("season") && jsonNextSeason["season"].GetType() == Json::Type::Object)
                @selectedType.nextSeason = MatchmakingTypeSeason(jsonNextSeason["season"]);

            if (selectedType.nextSeason !is null) {
                nextSeasonNumberEdit = selectedType.nextSeason.number;
                nextSeasonNameEdit = selectedType.nextSeason.name;
                nextSeasonStartDateEdit = Time::ParseUTC(selectedType.nextSeason.startDateTimestamp);
                nextSeasonMapPackIdEdit = selectedType.nextSeason.mxMapPackId;
                nextSeasonMapPackSecretEdit = selectedType.nextSeason.mxMapPackSecret;
                nextSeasonEndDateEnable = selectedType.nextSeason.endDateTimestamp != 0;
                if (nextSeasonEndDateEnable) nextSeasonEndDateEdit = Time::ParseUTC(selectedType.nextSeason.endDateTimestamp);
            }
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

    void PostNewSeason() {
        Json::Value@ postJson = Json::Object();
        postJson["matchmakingTypeId"] = selectedType.id;
        postJson["number"] = nextSeasonNumberEdit;
        postJson["name"] = nextSeasonNameEdit;
        postJson["mxMapPackId"] = nextSeasonMapPackIdEdit;
        postJson["mxMapPackSecret"] = nextSeasonMapPackSecretEdit;
        if (Time::ParseFormatInfo(nextSeasonStartDateEdit) != 0) postJson["startDate"] = Time::FormatInfoISO(nextSeasonStartDateEdit);
        if (nextSeasonEndDateEnable && Time::ParseFormatInfo(nextSeasonEndDateEdit) != 0) postJson["endDate"] = Time::FormatInfoISO(nextSeasonEndDateEdit);
        if (!nextSeasonEndDateEnable) postJson["endDate"] = Json::Parse("null");

        Json::Value@ resPost = API::PostAsync(Setting_BaseURL+"/admin/season", Json::Write(postJson));
        if (resPost.HasKey("season") && resPost["season"].GetType() == Json::Type::Object) {
            if (selectedType.season !is null && selectedType.season.isActive)
                @selectedType.nextSeason = MatchmakingTypeSeason(resPost["season"]);
            else
                @selectedType.season = MatchmakingTypeSeason(resPost["season"]);
            g_matchmakingTypes.RemoveAt(selectedTypeIndex);
            g_matchmakingTypes.InsertAt(selectedTypeIndex, selectedType);
        }
    }

    void PutSeason() {
        seasonToEditCompleted = false;
        seasonToEditInProgress = true;
        Json::Value@ putJson = Json::Object();
        if (useNextSeasonOnEdit) {
            putJson["number"] = nextSeasonNumberEdit;
            putJson["name"] = nextSeasonNameEdit;
            putJson["mxMapPackId"] = nextSeasonMapPackIdEdit;
            putJson["mxMapPackSecret"] = nextSeasonMapPackSecretEdit;
            if (Time::ParseFormatInfo(nextSeasonStartDateEdit) != 0) putJson["startDate"] = Time::FormatInfoISO(nextSeasonStartDateEdit);
            if (nextSeasonEndDateEnable && Time::ParseFormatInfo(nextSeasonEndDateEdit) != 0) putJson["endDate"] = Time::FormatInfoISO(nextSeasonEndDateEdit);
            if (!nextSeasonEndDateEnable) putJson["endDate"] = Json::Parse("null");
        } else {
            putJson["number"] = seasonNumberEdit;
            putJson["name"] = seasonNameEdit;
            putJson["mxMapPackId"] = seasonMapPackIdEdit;
            putJson["mxMapPackSecret"] = seasonMapPackSecretEdit;
            if (Time::ParseFormatInfo(seasonStartDateEdit) != 0) putJson["startDate"] = Time::FormatInfoISO(seasonStartDateEdit);
            if (seasonEndDateEnable && Time::ParseFormatInfo(seasonEndDateEdit) != 0) putJson["endDate"] = Time::FormatInfoISO(seasonEndDateEdit);
            if (!seasonEndDateEnable) putJson["endDate"] = Json::Parse("null");
        }

        Json::Value@ resPut = API::PutAsync(Setting_BaseURL+"/admin/season/"+seasonToEdit, Json::Write(putJson));

        if (resPut.HasKey("season") && resPut["season"].GetType() == Json::Type::Object) {
            if (useNextSeasonOnEdit) @selectedType.nextSeason = MatchmakingTypeSeason(resPut["season"]);
            else @selectedType.season = MatchmakingTypeSeason(resPut["season"]);
            g_matchmakingTypes.RemoveAt(selectedTypeIndex);
            g_matchmakingTypes.InsertAt(selectedTypeIndex, selectedType);
        }
        seasonToEditCompleted = true;
        seasonToEditInProgress = false;
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
        API::PostAsync(Setting_BaseURL+"/admin/season/"+selectedType.season.id+"/mappack", Json::Write(postJson));
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
        UI::Columns(3, "MMTypeDevTabTypeSeasonView", false);

        UI::BeginChild("EditTypeInfos");

        typeDisableEdit = UI::Checkbox("Disable##typeDisableEdit", typeDisableEdit);
        typeAllowSquadEdit = UI::Checkbox("Allow Squads##typeAllowSquadEdit", typeAllowSquadEdit);
        UI::SetNextItemWidth(250);
        typeNameEdit = UI::InputText("Set name##typeNameEdit", typeNameEdit);

        if (UI::GreenButton(Icons::FloppyO + " Save")) startnew(CoroutineFunc(PostMMType));
        vec2 posBottom = UI::GetCursorPos() + 43;

        UI::EndChild();

        UI::NextColumn();
        UI::BeginChild("ActiveSeason");
        if (selectedType.season !is null) {
            UI::Text((selectedType.season.isActive ? "\\$0f0Active\\$z " : (selectedType.season.isUpcoming ? "\\$7fcUpcoming\\$z " : "\\$949Last\\$z ")) + "Season info:");
            UI::SameLine();
            UI::TextDisabled("(ID: " + selectedType.season.id + ")");
            UI::AlignTextToFramePadding();
            UI::Text("Season #");
            UI::SameLine();
            UI::SetNextItemWidth(150);
            seasonNumberEdit = UI::InputUint("##seasonNumberEdit", seasonNumberEdit);
            UI::SetNextItemWidth(220);
            seasonNameEdit = UI::InputText("Name##seasonNameEdit", seasonNameEdit);
            UI::SetNextItemWidth(220);
            seasonStartDateEdit = UI::DateTimePicker("Start Date (UTC)##seasonStartDateEdit", seasonStartDateEdit, false, 5, false);
            seasonEndDateEnable = UI::Checkbox((seasonEndDateEnable ? "" : "End Date")+"##seasonEndDateEnable", seasonEndDateEnable);
            if (seasonEndDateEnable) {
                UI::SameLine();
                UI::SetNextItemWidth(187);
                seasonEndDateEdit = UI::DateTimePicker("End Date (UTC)##seasonEndDateEdit", seasonEndDateEdit, false, 5, false);
            }

            UI::BeginDisabled(seasonToEditInProgress);
            if (UI::Button(Icons::Pencil + " Edit")) {
                seasonToEdit = selectedType.season.id;
                useNextSeasonOnEdit = false;
                startnew(CoroutineFunc(PutSeason));
            }
            UI::EndDisabled();
            UI::SameLine();
            if (selectedType.season.isActive && UI::RedButton(Icons::TimesCircle + " End this season")) {
                Renderables::Add(DevEndSeasonConfirmationModalDialog(selectedType));
            }
            if (seasonToEditCompleted && seasonToEdit == selectedType.season.id) {
                UI::Text("\\$0f0"+Icons::Check+" \\$zEdit success");
            }
        } else UI::Text("\\$f00Error: This matchmaking does not have any seasons at all");
        posBottom.y = Math::Max(UI::GetCursorPos().y , posBottom.y) + 43;
        UI::EndChild();
        UI::NextColumn();
        UI::BeginChild("NextSeason");
        bool canCreateNewSeason = (
            selectedType.nextSeason is null &&
            selectedType.season !is null &&
            !selectedType.season.isActive &&
            selectedType.season.isUpcoming
        );

        if (canCreateNewSeason) {
            UI::Text("Create "+(selectedType.season.isActive ? "next" : "new")+" season:");
            UI::AlignTextToFramePadding();
            UI::Text("Season #");
            UI::SameLine();
            UI::SetNextItemWidth(150);
            nextSeasonNumberEdit = UI::InputUint("##nextSeasonNumberEdit", nextSeasonNumberEdit);
            UI::SetNextItemWidth(220);
            nextSeasonNameEdit = UI::InputText("Name##nextSeasonNameEdit", nextSeasonNameEdit);
            UI::SetNextItemWidth(220);
            nextSeasonMapPackIdEdit = UI::InputInt("Map Pack ID##nextSeasonMapPackIdEdit", nextSeasonMapPackIdEdit);
            UI::SetNextItemWidth(220);
            nextSeasonMapPackSecretEdit = UI::InputText("Map Pack Secret (API key, if any)##nextSeasonMapPackSecretEdit", nextSeasonMapPackSecretEdit, UI::InputTextFlags::CharsNoBlank);
            UI::SetNextItemWidth(220);
            nextSeasonStartDateEdit = UI::DateTimePicker("Start Date (UTC)##nextSeasonStartDateEdit", nextSeasonStartDateEdit, false, 5, false);
            nextSeasonEndDateEnable = UI::Checkbox((nextSeasonEndDateEnable ? "" : "End Date")+"##seasonEndDateEnable", nextSeasonEndDateEnable);
            if (nextSeasonEndDateEnable) {
                UI::SameLine();
                UI::SetNextItemWidth(187);
                nextSeasonEndDateEdit = UI::DateTimePicker("End Date (UTC)##nextSeasonEndDateEdit", nextSeasonEndDateEdit, false, 5, false);
            }
            if (UI::GreenButton("New season")) startnew(CoroutineFunc(PostNewSeason));
        } else {
            if (selectedType.nextSeason !is null && selectedType.season !is null && selectedType.season.isActive) {
                UI::Text("\\$7fcUpcoming\\$z Season info:");
                UI::SameLine();
                UI::TextDisabled("(ID: " + selectedType.nextSeason.id + ")");
                UI::AlignTextToFramePadding();
                UI::Text("Season #");
                UI::SameLine();
                UI::SetNextItemWidth(150);
                nextSeasonNumberEdit = UI::InputUint("##nextSeasonNumberEdit", nextSeasonNumberEdit);
                UI::SetNextItemWidth(220);
                nextSeasonNameEdit = UI::InputText("Name##nextSeasonNameEdit", nextSeasonNameEdit);
                UI::SetNextItemWidth(220);
                nextSeasonMapPackIdEdit = UI::InputInt("Map Pack ID##nextSeasonMapPackIdEdit", nextSeasonMapPackIdEdit);
                UI::SetNextItemWidth(220);
                nextSeasonMapPackSecretEdit = UI::InputText("Map Pack Secret (API key, if any)##nextSeasonMapPackSecretEdit", nextSeasonMapPackSecretEdit, UI::InputTextFlags::CharsNoBlank);
                UI::SetNextItemWidth(220);
                nextSeasonStartDateEdit = UI::DateTimePicker("Start Date (UTC)##nextSeasonStartDateEdit", nextSeasonStartDateEdit, false, 5, false);
                nextSeasonEndDateEnable = UI::Checkbox((nextSeasonEndDateEnable ? "" : "End Date")+"##nextSeasonEndDateEnable", nextSeasonEndDateEnable);
                if (nextSeasonEndDateEnable) {
                    UI::SameLine();
                    UI::SetNextItemWidth(187);
                    nextSeasonEndDateEdit = UI::DateTimePicker("End Date (UTC)##nextSeasonEndDateEdit", nextSeasonEndDateEdit, false, 5, false);
                }

                UI::BeginDisabled(seasonToEditInProgress);
                if (UI::Button(Icons::Pencil + " Edit")) {
                    seasonToEdit = selectedType.nextSeason.id;
                    useNextSeasonOnEdit = true;
                    startnew(CoroutineFunc(PutSeason));
                }
                UI::EndDisabled();
                if (seasonToEditCompleted && seasonToEdit == selectedType.nextSeason.id) {
                    UI::SameLine();
                    UI::Text("\\$0f0"+Icons::Check+" \\$zEdit success");
                }
            } else {
                if (selectedType.season !is null && !selectedType.season.isActive && selectedType.season.isUpcoming) {
                    UI::Text("The next season will be available soon.");
                    UI::Text("You can't create any more until the next season is underway.");
                } else {
                    UI::Text(Icons::AnimatedHourglass);
                }
            }
        }
        posBottom.y = Math::Max(UI::GetCursorPos().y, posBottom.y) + 43;
        UI::EndChild();
        UI::Columns(1);

        UI::SetCursorPos(vec2(posBottom.x, posBottom.y));

        UI::Separator();

        UI::Columns(2, "MMTypeDevTabMappackSettingsView");

        UI::BeginChild("Mappack");

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

        UI::NextColumn();
        UI::BeginChild("ModeSettings");
        UI::AlignTextToFramePadding();
        UI::Text("ModeSettings");
        UI::SameLine();
        if (UI::Button(Icons::Plus)) startnew(CoroutineFunc(AddNewSetting));
        UI::SameLine();
        if (UI::GreenButton(Icons::FloppyO + " Update settings")) startnew(CoroutineFunc(PostMMTypeModeSettings));

        if (UI::BeginTable("mmTypeModeSettings", 4, UI::TableFlags(UI::TableFlags::Resizable | UI::TableFlags::NoSavedSettings | UI::TableFlags::SizingStretchProp | UI::TableFlags::ScrollY))) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Setting Name", UI::TableColumnFlags::WidthFixed, 260);
            UI::TableSetupColumn("Setting Type", UI::TableColumnFlags::WidthFixed, 110);
            UI::TableSetupColumn("Setting Value", UI::TableColumnFlags::WidthFixed, 260);
            UI::TableSetupColumn("Remove", UI::TableColumnFlags::WidthStretch);
            UI::TableHeadersRow();

            UI::ListClipper clipper(selectedTypeModeSettings.Length);
            while(clipper.Step()) {
                for(int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
                {
                    UI::PushID("mmTypeModeSettings"+i);
                    UI::TableNextRow();

                    UI::TableSetColumnIndex(0);
                    UI::SetNextItemWidth(260 - 8);
                    selectedTypeModeSettings[i].settingName = UI::InputText("##settingNameEdit"+i, selectedTypeModeSettings[i].settingName);

                    UI::TableSetColumnIndex(1);
                    UI::SetNextItemWidth(110 - 8);
                    selectedTypeModeSettings[i].settingType = UI::InputText("##settingTypeEdit"+i, selectedTypeModeSettings[i].settingType);

                    UI::TableSetColumnIndex(2);
                    UI::SetNextItemWidth(260 - 8);
                    selectedTypeModeSettings[i].settingValue = UI::InputText("##settingValueEdit"+i, selectedTypeModeSettings[i].settingValue);

                    UI::TableSetColumnIndex(3);
                    if (UI::RedButton(Icons::TrashO)) {
                        @settingToRemove = selectedTypeModeSettings[i];
                        startnew(CoroutineFunc(RemoveSetting));
                    }

                    UI::PopID();
                }
            }

            UI::EndTable();
        }

        UI::EndChild();
        UI::Columns(1);
    }
}