class NoticeDevTab : Tab {
    Net::HttpRequest@ m_request;
    bool isError = false;
    string errorMsg = "";
    bool isLoading = false;
    bool noticeEnableEdit;
    string noticeIconEdit;
    string noticeTitleEdit;
    string noticeDescriptionEdit;

    string GetLabel() override { return "User Notice"; }
    bool IsVisible() override { return g_connectedPlayer.hasPermission("edit_user_notice"); }

    void Reload() override {
        noticeEnableEdit =  g_userNotice.isEnabled;
        noticeIconEdit =  g_userNotice.icon;
        noticeTitleEdit = g_userNotice.title;
        noticeDescriptionEdit = g_userNotice.description;
    }

    void CheckStartRequest()
    {
        if (UI::IsWindowAppearing()) {
            Reload();
        }
    }

    void CheckRequest()
    {
        CheckStartRequest();
    }

    void PostUserNotice() {
        Json::Value@ postJson = Json::Object();
        postJson["enable"] = noticeEnableEdit;
        postJson["icon"] = noticeIconEdit;
        postJson["title"] = noticeTitleEdit;
        postJson["description"] = noticeDescriptionEdit;

        Json::Value@ resPost = API::PostAsync(Setting_BaseURL+"/admin/usernotice", Json::Write(postJson));

        if (resPost.GetType() == Json::Type::Null) {
            isError = true;
            errorMsg = "Error while loading groups list";
            Log::Error(errorMsg);
            return;
        }

        if (resPost.HasKey("error")) {
            isError = true;
            errorMsg = resPost["error"]["message"];
            Log::Error(errorMsg);
            return;
        }

        g_userNotice.isEnabled = noticeEnableEdit;
        g_userNotice.icon = noticeIconEdit;
        g_userNotice.title = noticeTitleEdit;
        g_userNotice.description = noticeDescriptionEdit;
    }

    void Render() override
    {
        CheckRequest();

        if (isError) {
            UI::Text("\\$f00" + Icons::ExclamationTriangle + " \\$z" + errorMsg);
            return;
        }

        noticeEnableEdit = UI::Checkbox("Enable User notice##noticeEnableEdit", noticeEnableEdit);

        noticeIconEdit = UI::InputText("Set icon##noticeTitleEdit", noticeIconEdit);
        noticeTitleEdit = UI::InputText("Set title##noticeTitleEdit", noticeTitleEdit);
        noticeDescriptionEdit = UI::InputTextMultiline("Set description##noticeDescriptionEdit", noticeDescriptionEdit);

        if (UI::GreenButton("Save")) startnew(CoroutineFunc(PostUserNotice));
        UI::SameLine();
        if (UI::OrangeButton("Reset")) Reload();
    }
}