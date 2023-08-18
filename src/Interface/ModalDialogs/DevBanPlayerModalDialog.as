class DevBanPlayerModalDialog : ModalDialog
{
    Net::HttpRequest@ m_request;
    bool m_requestError = false;
    string resErrorString;
    Player@ playerToBan;
    string banTimeMin = "0";
    bool banOk = false;

    DevBanPlayerModalDialog(Player@ player)
    {
        super("\\$f90" + Icons::Ban + " \\$zBan "+player.displayName+"###DevBanPlayerModalDialog");
        @playerToBan = player;
        m_size = vec2(500, 170);
    }

    void RenderDialog() override
    {
        CheckBanRequest();
        UI::BeginDisabled(m_request !is null);
        float scale = UI::GetScale();
        UI::BeginChild("Content", vec2(0, -32) * scale);
        UI::Text("Enter temporary ban time in minutes (0 = permanent ban).");
        banTimeMin = UI::InputText("##banTimeMin", banTimeMin, false, UI::InputTextFlags::CharsDecimal);
        if (m_requestError) {
            UI::Text("\\$f00" + Icons::ExclamationTriangle +  " \\$zError:");
            UI::SameLine();
            UI::Text(resErrorString);
        }
        if (banOk) Close();
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
            StartBanRequest();
        }
        UI::EndDisabled();
    }

    void StartBanRequest()
    {
        string url = Setting_BaseURL + "/admin/player/ban";
        Json::Value@ postJson = Json::Object();
        postJson["accountId"] = playerToBan.accountId;
        postJson["time"] = banTimeMin;
        @m_request = API::Post(url, Json::Write(postJson));
    }

    void CheckBanRequest()
    {
        if (m_request !is null && m_request.Finished()) {
            string res = m_request.String();
            Log::Trace("DevBanPlayerModalDialog::CheckRequest : " + res);
            auto json = Json::Parse(res);
            @m_request = null;

            if (json.GetType() != Json::Type::Object) {
                Log::Error("DevBanPlayerModalDialog::CheckRequest : Error parsing response");
                m_requestError = true;
                resErrorString = "Error parsing response";
                return;
            }

            if (json.HasKey("error")) {
                resErrorString = json["error"]["message"];
                Log::Error("DevBanPlayerModalDialog::CheckRequest : Error: " + resErrorString);
                m_requestError = true;
                return;
            }

            banOk = json["banned"];
        }
    }
}