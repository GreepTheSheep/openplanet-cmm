class GroupsDevTab : Tab {
    Net::HttpRequest@ m_groupRequest;
    Net::HttpRequest@ m_permissionsRequest;
    bool isError = false;
    string errorMsg = "";
    bool isLoading = false;
    array<Group@> allGroups;
    array<Permission@> allPermissions;
    Group@ selectedGroup;
    array<int> selectedGroupPermissionsId;
    string groupColorEdit;
    string groupNameEdit;
    bool groupSelectChanged = false;

    string GetLabel() override { return "Groups"; }

    void StartRequest()
    {
        isLoading = true;

        @m_groupRequest = API::Get(Setting_BaseURL+"/admin/groups");
        @m_permissionsRequest = API::Get(Setting_BaseURL+"/admin/permissions");
    }

    void Reload() override {
        allGroups.RemoveRange(0, allGroups.Length);
        StartRequest();
    }

    void CheckStartRequest()
    {
        // If there's not already a request and the window is appearing, we start a new request
        if (m_groupRequest is null && UI::IsWindowAppearing()) {
            Reload();
        }
    }

    void CheckRequest()
    {
        CheckStartRequest();

        // If there's a request, check if it has finished
        if (m_groupRequest !is null && m_groupRequest.Finished()) {
            isLoading = false;
            // Parse the response
            string res = m_groupRequest.String();
            if (Meta::IsDeveloperMode()) trace("GroupsDevTab::CheckRequest: " + res);
            @m_groupRequest = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                isError = true;
                errorMsg = "Error while loading groups list";
                Log::Error(errorMsg);
                return;
            }

            if (json.HasKey("error")) {
                isError = true;
                errorMsg = json["error"]["message"];
                Log::Error(errorMsg);
                return;
            }

            for (uint i = 0; i < json["groups"].Length; i++) {
                Group@ group = Group(json["groups"][i]);
                allGroups.InsertLast(group);
            }

            SelectGroup(allGroups[0]);
        }

        if (m_permissionsRequest !is null && m_permissionsRequest.Finished()) {
            isLoading = false;
            // Parse the response
            string res = m_permissionsRequest.String();
            if (Meta::IsDeveloperMode()) trace("GroupsDevTab::CheckRequest: " + res);
            @m_permissionsRequest = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                isError = true;
                errorMsg = "Error while loading permissions list";
                Log::Error(errorMsg);
                return;
            }

            if (json.HasKey("error")) {
                isError = true;
                errorMsg = json["error"]["message"];
                Log::Error(errorMsg);
                return;
            }

            allPermissions.RemoveRange(0, allPermissions.Length);

            for (uint i = 0; i < json["permissions"].Length; i++) {
                Permission@ permission = Permission(json["permissions"][i]);
                allPermissions.InsertLast(permission);
            }
        }
    }

    void SelectGroup(Group@ group) {
        selectedGroupPermissionsId.RemoveRange(0, selectedGroupPermissionsId.Length);
        @selectedGroup = group;
        groupColorEdit = selectedGroup.color;
        groupNameEdit = selectedGroup.name;

        for (uint p = 0; p < selectedGroup.permissions.Length; p++) {
            selectedGroupPermissionsId.InsertLast(selectedGroup.permissions[p].id);
        }
    }

    void Render() override
    {
        CheckRequest();

        if (isLoading) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading...");
            return;
        }

        if (isError) {
            UI::Text("\\$f00" + Icons::ExclamationTriangle + " \\$z" + errorMsg);
            return;
        }

        if (UI::BlueButton(Icons::Refresh)) Reload();
        UI::SameLine();
        UI::GreenButton(Icons::Plus + " New Group (todo)");

        UI::Separator();

        if (allGroups.Length == 0) {
            UI::Text("\\$f00" + Icons::ExclamationTriangle + " \\$zGroups list is empty");
            return;
        }

        float width = UI::GetWindowSize().x*0.4;
        vec2 posTop = UI::GetCursorPos();

        UI::BeginChild("Summary", vec2(width,0));

        UI::Text("Select Group to view / edit");
        UI::SetNextItemWidth(width - 8);
        if (UI::BeginCombo("##GroupSelect", selectedGroup.nameWithColor)) {
            for (uint i = 0; i < allGroups.Length; i++) {
                groupSelectChanged = UI::Selectable(allGroups[i].nameWithColor, groupSelectChanged);
                if (groupSelectChanged) SelectGroup(allGroups[i]);
            }
            UI::EndCombo();
        }

        UI::TextDisabled("Identifier: " + selectedGroup.id);

        UI::Separator();
        UI::SetNextItemWidth(150);
        groupNameEdit = UI::InputText("Set name##groupNameEdit", groupNameEdit);
        UI::SetNextItemWidth(150);
        groupColorEdit = UI::InputText("Set color##groupColorEdit", groupColorEdit, UI::InputTextFlags::CharsHexadecimal | UI::InputTextFlags::CharsNoBlank);
        if (groupColorEdit.Length > 3) groupColorEdit = groupColorEdit.SubStr(0,3);
        if (groupColorEdit.Length == 2) groupColorEdit = "0" + groupColorEdit;
        if (groupColorEdit.Length == 1) groupColorEdit = "00" + groupColorEdit;
        UI::GreenButton("Update name / color (todo)");
        UI::Separator();

        UI::Text("Active permissions: ");
        for (uint p = 0; p < selectedGroup.permissions.Length; p++) {
            UI::Text("- " + selectedGroup.permissions[p].name);
            UI::SetPreviousTooltip(selectedGroup.permissions[p].description);
        }

        UI::EndChild();

        UI::SetCursorPos(posTop + vec2(width + 8, 0));
        UI::BeginChild("Permissions");
        UI::AlignTextToFramePadding();
        UI::Text("Update permissions for group: " + selectedGroup.nameWithColor);
        UI::SameLine();
        if (UI::GreenButton("Update (todo)")) {
            print(Json::Write(selectedGroupPermissionsId.ToJson()));
        }

        for (uint j = 0; j < allPermissions.Length; j++) {
            UI::PushID("SelectPermission"+allPermissions[j].id);
            bool permissionEdit = selectedGroupPermissionsId.Find(allPermissions[j].id) >= 0;
            permissionEdit = UI::Checkbox(allPermissions[j].name, permissionEdit);
            UI::SetPreviousTooltip(allPermissions[j].description);

            if (permissionEdit && selectedGroupPermissionsId.Find(allPermissions[j].id) == -1) selectedGroupPermissionsId.InsertLast(allPermissions[j].id);
            if (!permissionEdit && selectedGroupPermissionsId.Find(allPermissions[j].id) >= 0) selectedGroupPermissionsId.RemoveAt(selectedGroupPermissionsId.Find(allPermissions[j].id));
            UI::PopID();
        }

        UI::EndChild();
    }
}