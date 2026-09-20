class DevDeleteBadgeConfirmationModalDialog : ModalDialog
{
    Badge@ badgeToDelete;

    DevDeleteBadgeConfirmationModalDialog(Badge@ badge)
    {
        super(Icons::Trash + " \\$zDelete Badge "+badge.name+"###DevDeleteBadgeConfirmationModalDialog");
        @badgeToDelete = badge;
        m_size = vec2(500, 180);
    }

    void DeleteBadgeAsync() {
        string urlParams = "";
        dictionary params;
        params.Set("id", badgeToDelete.id);

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
        API::DeleteAsync(Setting_BaseURL+"/admin/badge" + urlParams);
    }

    void RenderDialog() override
    {
        if (!g_connectedPlayer.hasPermission("manage_badges")) {
            UI::Text("You don't have permissions !");
            if (UI::Button(Icons::Times + " Close")) Close();
            return;
        }

        UI::Text("Are you sure to delete " + badgeToDelete.name + " ?");
        UI::Markdown("Deleting this badge revokes it from **every** player and clears it from any player's highlighted profile badge.");

        UI::NewLine();
        if (UI::RedButton(Icons::Trash + " Delete")) {
            startnew(CoroutineFunc(DeleteBadgeAsync));
            Close();
        }
        UI::SameLine();
        if (UI::Button(Icons::Times + " Cancel")) Close();
    }
}