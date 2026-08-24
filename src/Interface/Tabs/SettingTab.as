class SettingTab : Tab {
    string GetID() override { return "setting"; }
    string GetLabel() override { return Icons::Cog; }
    string GetTooltip() override { return "Settings"; }
    vec4 GetColor() override { return vec4(0.2, 0.12, 0.12, 1); }

    void Render() override {
        RenderUISettingsTab();
    }
}