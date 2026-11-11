namespace UI {
    void BadgeImage(Badge@ badge, const float &in width = 19, const bool &in showTooltip = true, const bool &in showTooltipLargeImage = false, const bool &in showTooltipTitle = true, const bool &in showTooltipDescription = true) {
        auto img = Images::CachedFromURL(Setting_BaseURL+badge.iconUrl);

        if (img.m_texture !is null) {
            vec2 thumbSize = img.m_texture.GetSize();
            UI::Image(img.m_texture, vec2(
                width,
                thumbSize.y / (thumbSize.x / width)
            ));
            if (showTooltip) BadgeTooltip(badge, showTooltipLargeImage, showTooltipTitle, showTooltipDescription);
        } else if (!img.m_error) {
            UI::PushFont(Fonts::Header);
            UI::Text(Icons::AnimatedHourglass);
            UI::PopFont();
        } else if (img.m_notFound) {
            UI::PushFont(Fonts::Header);
            UI::Text("\\$fc0" + Icons::ExclamationTriangle);
            UI::PopFont();
            UI::SetPreviousTooltip("Badge icon not found");
        } else {
            UI::PushFont(Fonts::Header);
            UI::TextDisabled(Icons::Times);
            UI::PopFont();
            UI::SetPreviousTooltip("Error while loading badge icon");
        }
    }
}