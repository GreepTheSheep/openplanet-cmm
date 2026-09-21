namespace UI
{
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