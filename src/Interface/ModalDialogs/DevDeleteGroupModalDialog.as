class DevDeleteGroupModalDialog : ModalDialog
{
    Net::HttpRequest@ m_request;
    bool m_requestError = false;
    string resErrorString;
    Group@ groupToDelete;
    GroupsDevTab@ parentTab;
    bool deleteOk = false;

    DevDeleteGroupModalDialog(GroupsDevTab@ tab, Group@ group)
    {
        super("\\$f90" + Icons::Trash + " \\$zDelete group: "+group.name+"###DevDeleteGroupModalDialog");
        @groupToDelete = group;
        @parentTab = tab;
        m_size = vec2(500, 170);
    }

    void RenderDialog() override
    {
        CheckDeleteRequest();
        UI::BeginDisabled(m_request !is null);
        float scale = UI::GetScale();
        UI::BeginChild("Content", vec2(0, -32) * scale);
        UI::Text("Are you sure you want to delete group \""+groupToDelete.nameWithIconColor+"\\$z\"");
        UI::Text("All players with this group will be moved to the default group.");
        if (m_requestError) {
            UI::Text("\\$f00" + Icons::ExclamationTriangle +  " \\$zError:");
            UI::SameLine();
            UI::Text(resErrorString);
        }
        if (deleteOk) {
            parentTab.Reload();
            Close();
        }
        UI::EndChild();
        if (UI::Button(Icons::Times + " Cancel")) {
            Close();
        }
        UI::SameLine();
        if (m_request !is null) {
            UI::SetCursorPos(vec2(UI::GetWindowSize().x - 90 * scale, UI::GetCursorPos().y));
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass);
            UI::SameLine();
        }
        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 70 * scale, UI::GetCursorPos().y));
        if (UI::RedButton(Icons::Ban + " Yes")) {
            StartDeleteRequest();
        }
        UI::EndDisabled();
    }

    void StartDeleteRequest()
    {
        string url = Setting_BaseURL + "/admin/group";
        string urlParams = "";
        dictionary params;
        params.Set("id", tostring(groupToDelete.id));

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
        @m_request = API::Delete(url + urlParams);
    }

    void CheckDeleteRequest()
    {
        if (m_request !is null && m_request.Finished()) {
            string res = m_request.String();
            Log::Trace("DevDeleteGroupModalDialog::CheckRequest : " + res);
            auto json = Json::Parse(res);
            @m_request = null;

            if (json.GetType() != Json::Type::Object) {
                Log::Error("DevDeleteGroupModalDialog::CheckRequest : Error parsing response");
                m_requestError = true;
                resErrorString = "Error parsing response";
                return;
            }

            if (json.HasKey("error")) {
                resErrorString = json["error"]["message"];
                Log::Error("DevDeleteGroupModalDialog::CheckRequest : Error: " + resErrorString);
                m_requestError = true;
                return;
            }

            deleteOk = json["deleted"];
        }
    }
}