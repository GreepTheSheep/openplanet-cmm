class BroadcastNotificationDevTab : Tab {
    Net::HttpRequest@ m_request;
    bool isError = false;
    bool isSuccess = false;
    string errorMsg = "";
    array<string> possibleNotificationTypes = { "log", "warn", "alert", "silent" };
    string notificationTypeEdit = possibleNotificationTypes[0];
    string notificationMessageEdit;

    string GetLabel() override { return "Notification"; }
    bool IsVisible() override { return g_connectedPlayer.hasPermission("broadcast_messages"); }

    void PostNotification() {
        Json::Value@ postJson = Json::Object();
        postJson["notificationType"] = notificationTypeEdit;
        postJson["message"] = notificationMessageEdit;

        Json::Value@ resPost = API::PostAsync(Setting_BaseURL+"/admin/broadcastnotification", Json::Write(postJson));

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

        if (resPost.HasKey("success")) {
            isSuccess = resPost["success"];
        }
    }

    void Render() override
    {
        if (isError) {
            UI::Text("\\$f00" + Icons::ExclamationTriangle + " \\$z" + errorMsg);
        }

        if (UI::BeginCombo("Notification Type##notificationTypeEditSelect", notificationTypeEdit)) {
            for (uint i = 0; i < possibleNotificationTypes.Length; i++) {
                if (UI::Selectable(possibleNotificationTypes[i], notificationTypeEdit == possibleNotificationTypes[i]))
                    notificationTypeEdit = possibleNotificationTypes[i];
            }
            UI::EndCombo();
        }

        notificationMessageEdit = UI::InputTextMultiline("Set message##notificationMessageEdit", notificationMessageEdit);

        if (UI::GreenButton("Send")) startnew(CoroutineFunc(PostNotification));
        if (isSuccess) {
            UI::SameLine();
            UI::Text(Icons::Check + " Notification sent");
        }
    }
}