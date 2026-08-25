[Setting hidden]
int Setting_NotificationsVolume = 15;

[Setting hidden]
string Setting_MatchFoundAudio = Audio::MatchFoundSounds.GetKeys()[0];

[SettingsTab name="UI" icon="Cog" order="1"]
void RenderUISettingsTab() {
    if (UI::TreeNode(Icons::Kenney::SoundOn + " Audio", UI::TreeNodeFlags::Framed | UI::TreeNodeFlags::DefaultOpen)) {
        UI::SetNextItemWidth(300);
        Setting_NotificationsVolume = UI::SliderInt("##Setting_NotificationsVolume", Setting_NotificationsVolume, 0, 100, "%d %%", UI::SliderFlags::NoRoundToFormat);
        UI::SameLine();
        UI::Text((Setting_NotificationsVolume > 100 ? ("\\$f50"+Icons::ExclamationTriangle+"\\$z ") : "") + "Notifications Volume "+(Setting_NotificationsVolume == 0 ? Icons::Kenney::SoundOffAlt : Icons::Kenney::SoundOn));
        if (Setting_NotificationsVolume < 0) Setting_NotificationsVolume = 0;
        else if (Setting_NotificationsVolume == 1215752191) UI::Text("\\$f00YEPLOUD"); // Max integer value
        else if (Setting_NotificationsVolume > 100) UI::Text("\\$f50"+Icons::ExclamationTriangle+"\\$z Very Loud Volume Ahead! \\$666you've been warned...");
        else if (Setting_NotificationsVolume > 50) UI::TextDisabled(Icons::ExclamationTriangle+" Notifications can be loud");

        UI::SetNextItemWidth(300);
        if (UI::BeginCombo("##Setting_MatchFoundAudio", Setting_MatchFoundAudio)) {
            for (uint i = 0; i < Audio::MatchFoundSounds.GetKeys().Length; i++) {
                if (UI::Selectable(Audio::MatchFoundSounds.GetKeys()[i], Setting_MatchFoundAudio == Audio::MatchFoundSounds.GetKeys()[i])) Setting_MatchFoundAudio = Audio::MatchFoundSounds.GetKeys()[i];
            }
            UI::EndCombo();
        }
        UI::SameLine();
        UI::Text("Match found Notification sound");

        if (UI::Button(Icons::FileAudioO + " Test sound")) Audio::PlaySound(Audio::Sounds::MatchFound);
        UI::TreePop();
    }
}