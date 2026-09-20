class BadgesDevTab : Tab {
    Net::HttpRequest@ m_request;
    bool isError = false;
    string errorMsg = "";
    bool isLoading = false;
    array<Badge@> allBadges;
    string u_search;
    uint64 u_typingStart;
    int resLength = 0;
    Player@ selectPlayer;
    Group@ selectGroup;

    string GetLabel() override { return "Badges"; }
    bool IsVisible() override { return g_connectedPlayer.hasPermission("manage_badges"); }

    void StartRequest()
    {
        isLoading = true;
        string url = Setting_BaseURL+"/admin/badges";

        string urlParams = "";
        dictionary params;

        if (u_search.Length > 2) {
            params.Set("s", u_search);
        }

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

        @m_request = API::Get(url + urlParams);
    }

    void Reload() override {
        allBadges.RemoveRange(0, allBadges.Length);
        StartRequest();
    }

    void CheckStartRequest()
    {
        // If there's not already a request and the window is appearing, we start a new request
        if (m_request is null && UI::IsWindowAppearing()) {
            Reload();
        }

        if (m_request !is null) {
            return;
        }

        if (u_typingStart == 0) {
            return;
        }

        if (Time::Now > u_typingStart + 1000) {
            u_typingStart = 0;
            Reload();
        }
    }

    void CheckRequest()
    {
        CheckStartRequest();

        // If there's a request, check if it has finished
        if (m_request !is null && m_request.Finished()) {
            isLoading = false;
            // Parse the response
            string res = m_request.String();
            if (Meta::IsDeveloperMode()) trace("BadgesDevTab::CheckRequest: " + res);
            @m_request = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                isError = true;
                errorMsg = "Error while loading badges";
                Log::Error(errorMsg);
                return;
            }

            if (json.HasKey("error")) {
                isError = true;
                errorMsg = json["error"]["message"];
                Log::Error(errorMsg);
                return;
            }

            for (uint i = 0; i < json["badges"].Length; i++) {
                allBadges.InsertLast(Badge(json["badges"][i]));
            }

            resLength = json["badges"].Length;
            isError = false;
            errorMsg = "";
        }
    }

    void Render() override
    {
        CheckRequest();

        if (isLoading) {
            UI::Text(Icons::AnimatedHourglass + " Loading...");
            return;
        }

        if (isError) {
            UI::Text("\\$f00" + Icons::ExclamationTriangle + " \\$z" + errorMsg);
            return;
        }

        if (UI::GreenButton(Icons::Plus)) Renderables::Add(DevCreateBadgeModalDialog());
        UI::SetPreviousTooltip("Create a new badge");
        UI::SameLine();
        if (UI::BlueButton(Icons::Refresh)) Reload();

        UI::SameLine();
        UI::Text("Search:");
        UI::SameLine();
        bool changed = false;
        u_search = UI::InputText("##PlayerSearch", u_search, changed);
        if (changed) {
            u_typingStart = Time::Now;
        }
        if (resLength > 0) {
            UI::SameLine();
            UI::Text(resLength + " results.");
        }

        if (allBadges.Length == 0 && u_typingStart == 0) {
            UI::Text("Empty !");
            return;
        }

        if (UI::BeginTable("allBadgesList", 4, UI::TableFlags(UI::TableFlags::Resizable | UI::TableFlags::NoSavedSettings | UI::TableFlags::SizingStretchProp | UI::TableFlags::ScrollY))) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Badge", UI::TableColumnFlags::WidthFixed, 60);
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Description", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 80);
            UI::TableHeadersRow();

            UI::ListClipper clipper(allBadges.Length);
            while(clipper.Step()) {
                for(int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
                {
                    UI::PushID("ResCoBadge"+i);
                    Badge@ badge = allBadges[i];
                    UI::TableNextRow();

                    UI::TableSetColumnIndex(0);
                    auto img = Images::CachedFromURL(Setting_BaseURL+badge.iconUrl);

                    if (img.m_texture !is null) {
                        vec2 thumbSize = img.m_texture.GetSize();
                        float width = 28;
                        UI::Image(img.m_texture, vec2(
                            width,
                            thumbSize.y / (thumbSize.x / width)
                        ));
                        UI::BadgeTooltip(badge);
                    } else if (!img.m_error) {
                        UI::Text(Icons::AnimatedHourglass);
                    } else if (img.m_notFound) {
                        UI::Text("\\$fc0" + Icons::ExclamationTriangle);
                        UI::SetPreviousTooltip("Badge icon not found");
                    } else {
                        UI::Text(Icons::Times);
                        UI::SetPreviousTooltip("Error while loading avatar badge icon");
                    }

                    UI::TableSetColumnIndex(1);
                    UI::Text(badge.name);

                    UI::TableSetColumnIndex(2);
                    UI::Text(badge.description);

                    UI::TableSetColumnIndex(3);
                    if (UI::Button(Icons::Pencil)) {
                        Renderables::Add(DevEditBadgeModalDialog(badge));
                    }
                    UI::SetPreviousTooltip("Edit badge");
                    UI::SameLine();
                    if (UI::RedButton(Icons::Trash)) {
                        Renderables::Add(DevDeleteBadgeConfirmationModalDialog(badge));
                    }
                    UI::SetPreviousTooltip("Delete badge");
                    UI::PopID();
                }
            }
            UI::EndTable();
        }
    }
}