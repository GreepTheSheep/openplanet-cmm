namespace UI
{
    void PlayerInfoTooltip(Player@ player) {
        if (UI::BeginItemTooltip()) {
            UI::PushFont(Fonts::Header);
            if (player.group !is null) UI::Text(player.group.iconWithColor + "  " + player.displayName);
            else UI::Text(player.displayName);
            if (player.featuredBadge !is null) {
                UI::SameLine();
                UI::BadgeImage(player.featuredBadge, 28, false);
            }
            UI::PopFont();
            if (player.group !is null) UI::Text(player.group.nameWithColor);

            // Badges
            if (player.badges.Length > 0) UI::Separator();
            int newLineEvery = 4;
            int badgeIndexLine = 0;
            for (uint b = 0; b < player.badges.Length; b++) {
                UI::PushID("PlayerBadge"+player.badges[b].id);
                UI::AlignTextToFramePadding();
                UI::BadgeImage(player.badges[b].badge, 20, false);
                UI::PopID();
                if (badgeIndexLine == newLineEvery) {
                    badgeIndexLine = 0;
                } else {
                    UI::SameLine();
                    badgeIndexLine++;
                }
            }

            UI::EndTooltip();
        }
    }

    void BadgeTooltip(Badge@ badge, const bool &in showLargeImage = false, const bool &in showTitle = true, const bool &in showDescription = true) {
        if ((showLargeImage || showTitle || (showDescription && badge.description.Length > 0)) && UI::BeginItemTooltip()) {
            if (showLargeImage) {
                auto img = Images::CachedFromURL(Setting_BaseURL+badge.iconUrl);
                if (img.m_texture !is null) {
                    vec2 thumbSize = img.m_texture.GetSize();
                    float width = 75;
                    UI::AlignTextToFramePadding();
                    UI::Image(img.m_texture, vec2(
                        width,
                        thumbSize.y / (thumbSize.x / width)
                    ));
                } else if (!img.m_error) {
                    UI::PushFont(Fonts::Header);
                    UI::Text(Icons::AnimatedHourglass);
                    UI::PopFont();
                } else if (img.m_notFound) {
                    UI::PushFont(Fonts::Header);
                    UI::Text("\\$fc0" + Icons::ExclamationTriangle);
                    UI::PopFont();
                } else {
                    UI::PushFont(Fonts::Header);
                    UI::Text(Icons::Times);
                    UI::PopFont();
                }
                UI::SameLine();
            }
            if (showTitle) {
                UI::PushFont(Fonts::SubHeader);
                UI::Text(badge.name);
                UI::PopFont();
            }
            if (showDescription && badge.description.Length > 0) UI::TextDisabled(badge.description);
            UI::EndTooltip();
        }
    }
}