class SquadTab : Tab {
    Net::HttpRequest@ m_squadGetRequest;
    bool isLoading = false;
    bool isError = false;
    bool hideInviteCode = false;
    string errorMsg = "";
    string newSquadName = g_connectedPlayer.displayName + "'s squad";
    string squadChatMessage = "";
    string squadJoinCode = "";
    Meta::PluginCoroutine@ squadFetchLoopCoroutine;

    string GetLabel() override { return Icons::Kenney::Users + " Squad"; }
    vec4 GetColor() override { return vec4(0.05f, 0.47f, 0, 1); }

    void StartRequest()
    {
        isLoading = true;
        @m_squadGetRequest = API::Get(Setting_BaseURL+"/squad");
    }

    void Reload() override {
        StartRequest();
    }

    void CheckStartRequest()
    {
        // If there's not already a request and the window is appearing, we start a new request
        if (g_activeSquad is null && m_squadGetRequest is null && UI::IsWindowAppearing()) {
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
            if (squadFetchLoopCoroutine is null || !squadFetchLoopCoroutine.IsRunning()) @squadFetchLoopCoroutine = startnew(Squad::fetchSquadLoop);
        }
    }

    void CreateSquad() {
        LeaveSquad(); // leave squad (even if player don't have one)

        Json::Value@ postJson = Json::Object();
        postJson["name"] = newSquadName;
        Json::Value@ newSquad = API::PostAsync(Setting_BaseURL+"/squad/new", Json::Write(postJson));

        @g_activeSquad = Squad(newSquad["squad"]);
        if (squadFetchLoopCoroutine is null || !squadFetchLoopCoroutine.IsRunning()) @squadFetchLoopCoroutine = startnew(Squad::fetchSquadLoop);
    }

    void LeaveSquad() {
        API::PostAsync(Setting_BaseURL+"/squad/leave");
        @g_activeSquad = null;
        @squadFetchLoopCoroutine = null;
    }

    void JoinSquad() {
        LeaveSquad(); // leave squad (even if player don't have one)

        Json::Value@ postJson = Json::Object();
        postJson["code"] = squadJoinCode;
        Json::Value@ newSquad = API::PostAsync(Setting_BaseURL+"/squad/join", Json::Write(postJson));

        @g_activeSquad = Squad(newSquad["squad"]);
        squadJoinCode = "";
        if (squadFetchLoopCoroutine is null || !squadFetchLoopCoroutine.IsRunning()) @squadFetchLoopCoroutine = startnew(Squad::fetchSquadLoop);
    }

    void PostSquadMessage() {
        if (squadChatMessage.Length == 0) return;
        Json::Value@ postJson = Json::Object();
        postJson["message"] = squadChatMessage;
        squadChatMessage = "";
        Json::Value@ newSquad = API::PostAsync(Setting_BaseURL+"/squad/chat", Json::Write(postJson));

        @g_activeSquad = Squad(newSquad["squad"]);
        if (squadFetchLoopCoroutine is null || !squadFetchLoopCoroutine.IsRunning()) @squadFetchLoopCoroutine = startnew(Squad::fetchSquadLoop);
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
            bool pressedEnterCreate = false;
            newSquadName = UI::InputText("Set squad name##squadNameCreate", newSquadName, pressedEnterCreate, UI::InputTextFlags::EnterReturnsTrue);

            UI::BeginDisabled(newSquadName.Length == 0);
            if (pressedEnterCreate || UI::GreenButton("Create Squad")) startnew(CoroutineFunc(CreateSquad));
            UI::EndDisabled();

            UI::Separator();

            UI::Text("Join a Squad:");
            UI::SetNextItemWidth(300);
            bool pressedEnterJoin = false;
            squadJoinCode = UI::InputText("Squad invite code##squadJoinCode", squadJoinCode, pressedEnterJoin, UI::InputTextFlags::EnterReturnsTrue | UI::InputTextFlags::CharsDecimal | (hideInviteCode ? UI::InputTextFlags::Password : 0));
            if (squadJoinCode.Length > 6) squadJoinCode = squadJoinCode.SubStr(0,6);

            hideInviteCode = UI::Checkbox("Hide Invite Code", hideInviteCode);
            UI::BeginDisabled(squadJoinCode.Length != 6);
            if (pressedEnterJoin || UI::GreenButton("Join Squad")) startnew(CoroutineFunc(JoinSquad));
            UI::EndDisabled();
        } else {
            float width = UI::GetWindowSize().x*0.4;
            vec2 posTop = UI::GetCursorPos();

            UI::BeginChild("Summary", vec2(width,0));
            UI::Text(g_activeSquad.name);

            UI::AlignTextToFramePadding();
            UI::Text("Invite Code:");
            UI::SameLine();
            UI::SetNextItemWidth(70);
            UI::InputText("##squadInviteCode", tostring(g_activeSquad.inviteCode), UI::InputTextFlags::ReadOnly | (hideInviteCode ? UI::InputTextFlags::Password : UI::InputTextFlags::AutoSelectAll));
            UI::SameLine();
            if (UI::Button(Icons::Clipboard)) IO::SetClipboard(tostring(g_activeSquad.inviteCode));
            hideInviteCode = UI::Checkbox("Hide Invite Code", hideInviteCode);

            UI::NewLine();
            if (UI::RedButton("Leave Squad")) startnew(CoroutineFunc(LeaveSquad));

            UI::Separator();
            UI::NewLine();

            UI::Text("Players:");
            UI::BeginChild("SquadPlayers");
            for (uint p = 0; p < g_activeSquad.players.Length; p++) {
                Player@ player = g_activeSquad.players[p];
                UI::Text("- " + player.displayName);
                if (player.accountId == g_activeSquad.ownerPlayer) {
                    UI::SameLine();
                    UI::Text("\\$ff0" + Icons::IdBadge);
                    UI::SetPreviousTooltip("Squad Owner");
                }
            }
            UI::EndChild(); // SquadPlayers
            UI::EndChild(); // Summary

            UI::SetCursorPos(posTop + vec2(width + 8, 0));
            UI::BeginChild("SquadChat");
            UI::SetNextItemWidth(UI::GetWindowSize().x-200);
            bool pressedEnterChat = false;
            squadChatMessage = UI::InputText("##SquadChatMessage", squadChatMessage, pressedEnterChat, UI::InputTextFlags::EnterReturnsTrue | UI::InputTextFlags::NoHorizontalScroll);
            UI::SameLine();
            if (UI::BlueButton(Icons::PaperPlane + " Chat") || pressedEnterChat) startnew(CoroutineFunc(PostSquadMessage));
            for (uint i = 0; i < g_activeSquad.messages.Length; i++) {
                SquadMessage@ msg = g_activeSquad.messages[i];
                if (msg.accountId == "system") UI::Text(COLOR_STR + Icons::Server + " " + msg.playerName + "\\$z " + msg.message);
                else UI::Text("\\$4f4" + Icons::User + " \\$a60" + msg.playerName + "\\$z " + msg.message);
            }
            UI::EndChild(); // SquadChat
        }
    }
}