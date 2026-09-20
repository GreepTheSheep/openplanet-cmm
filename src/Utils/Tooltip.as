namespace UI
{
    void BadgeTooltip(Badge@ badge) {
        if (UI::BeginItemTooltip()) {
            auto img = Images::CachedFromURL(Setting_BaseURL+badge.iconUrl);
            UI::AlignTextToFramePadding();
            if (img.m_texture !is null) {
                vec2 thumbSize = img.m_texture.GetSize();
                float width = 75;
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
            UI::PushFont(Fonts::Header);
            UI::Text(badge.name);
            UI::PopFont();
            if (badge.description.Length > 0) UI::TextWrapped(badge.description);
            UI::EndTooltip();
        }
    }
}