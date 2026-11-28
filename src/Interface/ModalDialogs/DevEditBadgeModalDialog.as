class DevEditBadgeModalDialog : ModalDialog
{
    Badge@ badgeToEdit;
    string nameEdit;
    bool notNullDescriptionEdit;
    string descriptionEdit;
    string iconEdit;

    DevEditBadgeModalDialog(Badge@ badge)
    {
        super(Icons::Pencil + " \\$zEdit Badge "+badge.name+"###DevEditBadgeModalDialog");
        @badgeToEdit = badge;
        nameEdit = badge.name;
        descriptionEdit = badge.description;
        notNullDescriptionEdit = badge.description.Length > 0;
        m_size = vec2(600, 280);
    }

    void UpdateBadgeAsync() {
        Json::Value@ putJson = Json::Object();
        putJson["id"] = badgeToEdit.id;
        if (nameEdit.Length > 0) putJson["name"] = nameEdit;
        if (notNullDescriptionEdit) putJson["description"] = descriptionEdit;
        if (iconEdit.Length > 0) putJson["icon"] = iconEdit;
        API::PutAsync(Setting_BaseURL+"/admin/badge", Json::Write(putJson));
    }

    void RenderDialog() override
    {
        if (!g_connectedPlayer.hasPermission("manage_badges")) {
            UI::Text("You don't have permissions !");
            if (UI::Button(Icons::Times + " Close")) Close();
            return;
        }

        UI::Text("Update badge: " + badgeToEdit.name);

        nameEdit = UI::InputText("Set name##badgeNameEdit", nameEdit);

        notNullDescriptionEdit = UI::Checkbox("###notNullDescriptionEdit", notNullDescriptionEdit);
        UI::SetItemTooltip("If checked, description set next will be used. If not checked, description will not being modified.");
        UI::SameLine();
        UI::BeginDisabled(!notNullDescriptionEdit);
        descriptionEdit = UI::InputText("Set description##badgeDescriptionEdit", descriptionEdit);
        UI::EndDisabled();

        iconEdit = UI::InputText("Set Base64-encoded image##badgeIconEdit", iconEdit);
        UI::SetItemTooltip("If empty, the image will not being modified.");

        UI::NewLine();
        if (UI::Button("Use a Image to Base64 converter")) OpenBrowserURL("https://base64.guru/converter/encode/image");

        UI::NewLine();
        if (UI::GreenButton(Icons::FloppyO + " Save")) {
            startnew(CoroutineFunc(UpdateBadgeAsync));
            Close();
        }
        UI::SameLine();
        if (UI::Button(Icons::Times + " Cancel")) Close();
    }
}