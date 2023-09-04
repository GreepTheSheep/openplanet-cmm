class SquadTab : Tab {
    Net::HttpRequest@ m_squadGetRequest;
    bool isLoading = false;
    bool isError = false;
    bool hideInviteCode = false;
    string errorMsg = "";
    string newSquadName = g_connectedPlayer.displayName + "'s squad";

    string GetLabel() override { return Icons::Users + " Squad"; }
    vec4 GetColor() override { return vec4(0.05f, 0.47f, 0, 1); }

    void StartRequest()
    {
        isLoading = true;
        @m_squadGetRequest = API::Get(Setting_BaseURL+"/matchmaking/squad");
    }

    void Reload() override {
        StartRequest();
    }

    void CheckStartRequest()
    {
        // If there's not already a request and the window is appearing, we start a new request
        if (m_squadGetRequest is null && UI::IsWindowAppearing()) {
            Reload();
        }
    }

    void CheckRequest()
    {
        CheckStartRequest();

        // If there's a request, check if it has finished
        if (m_squadGetRequest !is null && m_squadGetRequest.Finished()) {
            isLoading = false;
            // Parse the response
            string res = m_squadGetRequest.String();
            if (Meta::IsDeveloperMode()) trace("SquadTab::CheckRequest: " + res);
            @m_squadGetRequest = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                isError = true;
                errorMsg = "Error while loading squad";
                Log::Error(errorMsg);
                return;
            }

            if (json.HasKey("error")) {
                int errCode = json["error"]["code"];
                errorMsg = json["error"]["message"];
                if (errCode == 404) {
                    Log::Log(errorMsg);
                    return;
                }
                isError = true;
                Log::Error(errorMsg);
                return;
            }

            @g_activeSquad = Squad(json["squad"]);
        }
    }

    void CreateSquad() {
        LeaveSquad(); // leave squad (even if player don't have one)

        Json::Value@ postJson = Json::Object();
        postJson["name"] = newSquadName;
        Json::Value@ newSquad = API::PostAsync(Setting_BaseURL+"/matchmaking/squad/new", Json::Write(postJson));

        @g_activeSquad = Squad(newSquad["squad"]);
    }

    void LeaveSquad() {
        API::PostAsync(Setting_BaseURL+"/matchmaking/squad/leave");
        @g_activeSquad = null;
    }

    void Render() override {
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

        if (g_activeSquad is null) {
            UI::Text("Create a Squad and invite players on it to queue together.");
            UI::SetNextItemWidth(300);
            newSquadName = UI::InputText("Set squad name##squadNameCreate", newSquadName);

            hideInviteCode = UI::Checkbox("Hide Invite Code", hideInviteCode);
            if (UI::GreenButton("Create Squad")) {
                startnew(CoroutineFunc(CreateSquad));
            }
        } else {
            UI::Text(g_activeSquad.name);
            UI::Text("Squad Owner: " + g_activeSquad.ownerPlayer.displayName);
            UI::Text(g_activeSquad.players.Length + " players on this squad");

            UI::SetNextItemWidth(70);
            UI::Text("Invite Code:");
            UI::SameLine();
            UI::InputText("##squadInviteCode", tostring(g_activeSquad.inviteCode), UI::InputTextFlags::ReadOnly | (hideInviteCode ? UI::InputTextFlags::Password : 0));
            UI::SameLine();
            if (UI::Button(Icons::Clipboard)) IO::SetClipboard(tostring(g_activeSquad.inviteCode));
            hideInviteCode = UI::Checkbox("Hide Invite Code", hideInviteCode);

            if (UI::RedButton("Leave Squad")) {
                startnew(CoroutineFunc(LeaveSquad));
            }
        }
    }
}