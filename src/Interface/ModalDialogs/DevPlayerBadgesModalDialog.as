class DevPlayerBadgesModalDialog : ModalDialog
{
    Net::HttpRequest@ m_request;
    Net::HttpRequest@ m_userBadgesRequest;
    bool m_requestIsLoading = false;
    bool m_requestError = false;
    string resErrorString;
    Player@ playerToManageBadges;
    array<int> selectedBadgesId;
    array<Badge@> m_allBadges;
    array<PlayerBadge@> m_playerBadges;

    DevPlayerBadgesModalDialog(Player@ player)
    {
        super(Icons::Kenney::BadgeAlt + " \\$zBadges for "+player.displayName+"###DevPlayerBadgesModalDialog");
        @playerToManageBadges = player;
        m_size = vec2(400, 300);
    }

    void Reload() {
        m_playerBadges.RemoveRange(0, m_playerBadges.Length);
        StartRequest();
    }

    void CheckRequest()
    {
        CheckStartRequest();

        // If there's a request, check if it has finished
        if (m_userBadgesRequest !is null && m_userBadgesRequest.Finished()) {
            m_requestIsLoading = false;
            // Parse the response
            string res = m_userBadgesRequest.String();
            if (Meta::IsDeveloperMode()) trace("DevPlayerBadgesModalDialog::m_userBadgesRequest::CheckRequest: " + res);
            @m_userBadgesRequest = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                m_requestError = true;
                resErrorString = "Error while loading player's badge";
                Log::Error(resErrorString);
                return;
            }

            if (json.HasKey("error")) {
                m_requestError = true;
                resErrorString = json["error"]["message"];
                Log::Error(resErrorString);
                return;
            }

            selectedBadgesId.RemoveRange(0, selectedBadgesId.Length);
            for (uint i = 0; i < json["badges"].Length; i++) {
                PlayerBadge@ playerBadge = PlayerBadge(json["badges"][i]);
                m_playerBadges.InsertLast(playerBadge);
                selectedBadgesId.InsertLast(playerBadge.badge.id);
            }

            m_requestError = false;
            resErrorString = "";
        }

        if (m_request !is null && m_request.Finished()) {
            m_requestIsLoading = false;
            // Parse the response
            string res = m_request.String();
            if (Meta::IsDeveloperMode()) trace("DevPlayerBadgesModalDialog::m_request::CheckRequest: " + res);
            @m_request = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                m_requestError = true;
                resErrorString = "Error while loading all badges";
                Log::Error(resErrorString);
                return;
            }

            if (json.HasKey("error")) {
                m_requestError = true;
                resErrorString = json["error"]["message"];
                Log::Error(resErrorString);
                return;
            }

            for (uint i = 0; i < json["badges"].Length; i++) {
                m_allBadges.InsertLast(Badge(json["badges"][i]));
            }

            m_requestError = false;
            resErrorString = "";
        }
    }

    void CheckStartRequest()
    {
        // If there's not already a request and the window is appearing, we start a new request
        if (m_userBadgesRequest is null && UI::IsWindowAppearing()) {
            Reload();
        }

        if (m_userBadgesRequest !is null) {
            return;
        }
    }

    void StartRequest()
    {
        m_requestIsLoading = true;
        string url = Setting_BaseURL+"/admin/badges";
        string userBadgesUrl = Setting_BaseURL+"/user/badges";
        string urlParams = "";
        dictionary params;
        params.Set("playerId", playerToManageBadges.id);

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

        @m_request = API::Get(url);
        @m_userBadgesRequest = API::Get(userBadgesUrl + urlParams);
    }

    void UpdatePlayerBadges() {
        Json::Value@ putJson = Json::Object();
        putJson["id"] = playerToManageBadges.accountId;
        putJson["badges"] = selectedBadgesId.ToJson();

        Json::Value@ resPut = API::PutAsync(Setting_BaseURL+"/admin/player/badges", Json::Write(putJson));

        @playerToManageBadges = Player(resPut);
    }

    void RenderDialog() override
    {
        CheckRequest();
        if (g_connectedPlayer.hasPermission("manage_badges")) {
            UI::AlignTextToFramePadding();
            UI::Text("Update badges for player: " + playerToManageBadges.displayName);
            UI::SameLine();
            if (UI::GreenButton(Icons::FloppyO + " Update badges")) startnew(CoroutineFunc(UpdatePlayerBadges));
            UI::NewLine();
            UI::BeginChild("BadgeList");

            for (uint b = 0; b < m_allBadges.Length; b++) {
                UI::PushID("SelectBadge"+m_allBadges[b].id);
                UI::AlignTextToFramePadding();

                bool badgeEdit = selectedBadgesId.Find(m_allBadges[b].id) >= 0;
                badgeEdit = UI::Checkbox("###SelectBadge"+m_allBadges[b].id, badgeEdit);
                UI::SameLine();
                UI::BadgeImage(m_allBadges[b], 24, true, true);

                if (badgeEdit && selectedBadgesId.Find(m_allBadges[b].id) == -1) selectedBadgesId.InsertLast(m_allBadges[b].id);
                if (!badgeEdit && selectedBadgesId.Find(m_allBadges[b].id) >= 0) selectedBadgesId.RemoveAt(selectedBadgesId.Find(m_allBadges[b].id));
                UI::PopID();
            }
            UI::EndChild();
        } else {
            UI::Text("Active badges for player: " + playerToManageBadges.displayName);
            UI::NewLine();
            UI::BeginChild("BadgeList");

            int newLineEvery = 4;
            int badgeIndexLine = 0;
            for (uint b = 0; b < m_playerBadges.Length; b++) {
                UI::BadgeImage(m_playerBadges[b].badge, 24, true, true);
                if (badgeIndexLine == newLineEvery) {
                    badgeIndexLine = 0;
                } else {
                    if (b != m_playerBadges.Length - 1) UI::SameLine();
                    badgeIndexLine++;
                }
            }
            UI::EndChild();
        }
    }
}