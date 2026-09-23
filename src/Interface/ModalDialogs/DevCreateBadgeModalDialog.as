class DevCreateBadgeModalDialog : ModalDialog
{
    Badge@ badgeToCreate;
    string nameEdit;
    string descriptionEdit;
    string iconEdit;

    DevCreateBadgeModalDialog()
    {
        super(Icons::Kenney::BadgeAlt + " \\$zCreate new Badge###DevCreateBadgeModalDialog");
        m_size = vec2(600, 280);
    }

    void UpdateBadgeAsync() {
        Json::Value@ postJson = Json::Object();
        postJson["name"] = nameEdit;
        if (descriptionEdit.Length > 0) postJson["description"] = descriptionEdit;
        postJson["icon"] = iconEdit;
        API::PostAsync(Setting_BaseURL+"/admin/badge", Json::Write(postJson));
    }

    void RenderDialog() override
    {
        if (!g_connectedPlayer.hasPermission("manage_badges")) {
            UI::Text("You don't have permissions !");
            if (UI::Button(Icons::Times + " Close")) Close();
            return;
        }

        UI::Text("Create a new badge");

        nameEdit = UI::InputText("Set name##badgeNameEdit", nameEdit);

        descriptionEdit = UI::InputText("Set description##badgeDescriptionEdit", descriptionEdit);

        iconEdit = UI::InputText("Set Base64-encoded image##badgeIconEdit", iconEdit);

        UI::NewLine();
        if (UI::Button("Use a Image to Base64 converter")) OpenBrowserURL("https://base64.guru/converter/encode/image");

        UI::NewLine();
        UI::BeginDisabled(nameEdit.Length == 0 || iconEdit.Length == 0);
        if (UI::GreenButton(Icons::FloppyO + " Save")) {
            startnew(CoroutineFunc(UpdateBadgeAsync));
            Close();
        }
        UI::EndDisabled();
        UI::SameLine();
        if (UI::Button(Icons::Times + " Cancel")) Close();

        if (nameEdit.Length == 0 || iconEdit.Length == 0) UI::Text("\\$fa0" + Icons::ExclamationTriangle + "\\$z A name and an icon is required to create a new badge.");
    }
}