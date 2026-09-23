class UserTab : Tab {
    string GetID() override { return "user"; }
    string GetLabel() override { return Icons::User; }
    string GetTooltip() override { return g_connectedPlayer.displayName; }
    vec4 GetColor() override { return vec4(0.72, 0, 0.515, 1); }

    int badgeIdToSetFeatured;

    void SetPlayerFeaturedBadgeAsync() {
        // badgeIdToSetFeatured == 0 : Remove featured badge
        // badge id cannot be 0 or less, so that's fine

        Json::Value@ putJson = Json::Object();
        if (badgeIdToSetFeatured == 0) putJson["badgeId"] = Json::Parse("null");
        else putJson["badgeId"] = badgeIdToSetFeatured;
        Json::Value@ resPut = API::PutAsync(Setting_BaseURL + "/user/featured-badge", Json::Write(putJson)); // Should return the full updated Player entity

        @g_connectedPlayer = Player(resPut);
    }

    void Render() override {
        UI::PushFont(Fonts::Header);
        UI::Text(g_connectedPlayer.displayName);
        UI::PopFont();
        if (g_connectedPlayer.featuredBadge !is null) {
            UI::SameLine();
            UI::BadgeImage(g_connectedPlayer.featuredBadge, 24);
            if (UI::BeginPopupContextItem("PlayerFeaturedBadge")) {
                UI::AlignTextToFramePadding();
                UI::BadgeImage(g_connectedPlayer.featuredBadge, 26, false);
                UI::SameLine();
                UI::Text(g_connectedPlayer.featuredBadge.name);
                if (UI::MenuItem("Remove featured")) {
                    badgeIdToSetFeatured = 0;
                    startnew(CoroutineFunc(SetPlayerFeaturedBadgeAsync));
                }
                UI::EndPopup();
            }
        }

        if (
            g_connectedPlayer.badges.Length > 0 &&
            UI::TreeNode(
                Icons::Kenney::BadgeAlt + " "+g_connectedPlayer.badges.Length+" badge"+(g_connectedPlayer.badges.Length>1?"s":"")+"###UserTabBadgesNode",
                UI::TreeNodeFlags::DefaultOpen
            )
            ) {

            UI::TextDisabled("Right click on a badge to feature it next to your username");

            int newLineEvery = 4;
            int badgeIndexLine = 0;
            for (uint b = 0; b < g_connectedPlayer.badges.Length; b++) {
                UI::PushID("PlayerBadge"+g_connectedPlayer.badges[b].id);
                UI::AlignTextToFramePadding();
                UI::BadgeImage(g_connectedPlayer.badges[b].badge, 32, true, true);
                if (UI::BeginPopupContextItem("PlayerBadge"+g_connectedPlayer.badges[b].id)) {
                    UI::AlignTextToFramePadding();
                    UI::BadgeImage(g_connectedPlayer.badges[b].badge, 26, false);
                    UI::SameLine();
                    UI::Text(g_connectedPlayer.badges[b].badge.name);
                    if (UI::MenuItem("Set as featured", "", g_connectedPlayer.featuredBadgeId == g_connectedPlayer.badges[b].badge.id)) {
                        if (g_connectedPlayer.featuredBadgeId == g_connectedPlayer.badges[b].badge.id) {
                            // Remove featured badge
                            badgeIdToSetFeatured = 0;
                            startnew(CoroutineFunc(SetPlayerFeaturedBadgeAsync));
                        } else {
                            // Set this badge as featured
                            badgeIdToSetFeatured = g_connectedPlayer.badges[b].badge.id;
                            startnew(CoroutineFunc(SetPlayerFeaturedBadgeAsync));
                        }
                    }
                    UI::EndPopup();
                }
                UI::PopID();
                if (badgeIndexLine == newLineEvery) {
                    badgeIndexLine = 0;
                } else {
                    UI::SameLine();
                    badgeIndexLine++;
                }
            }
            UI::TreePop();
        }
    }
}