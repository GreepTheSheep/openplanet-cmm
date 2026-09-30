class InfoTab : Tab {
    string GetID() override { return "info"; }
    string GetLabel() override { return Icons::InfoCircle; }
    string GetTooltip() override { return "Info"; }
    vec4 GetColor() override { return vec4(0.47f, 0.47f, 0.47f, 1); }

    void Render() override {
        if (UI::GreenButton(Icons::Patreon + " \\$zSupport " + PLUGIN_NAME_SHORT)) OpenBrowserURL("https://patreon.com/Greep");
        UI::SameLine();
        if (UI::Button(Icons::DiscordAlt + " Discord")) OpenBrowserURL("https://greep.fr/#/discord");
        UI::SameLine();
        if (UI::Button(Icons::Heartbeat + " Plugin Home")) OpenBrowserURL("https://openplanet.dev/plugin/" + Meta::ExecutingPlugin().ID);

        UI::PushFont(Fonts::Header);
        UI::SeparatorText(Icons::Plug + " \\$z Plugin");
        UI::PopFont();
        UI::Text("Version \\$777" + Meta::ExecutingPlugin().Version);
#if CMM_DEV_BUILD
        UI::SameLine();
        UI::Text("\\$777(\\$f00" + Icons::Wrench + " \\$777Dev build)");
#endif
        UI::Text("Plugin ID \\$777" + Meta::ExecutingPlugin().ID);
        UI::Text("Site ID \\$777" + Meta::ExecutingPlugin().SiteID);
        UI::Text("Type \\$777" + tostring(Meta::ExecutingPlugin().Type));
#if SIG_DEVELOPER
        UI::SameLine();
        UI::Text("\\$777(\\$f39" + Icons::Code + " \\$777Openplanet Dev signature)");
#endif
#if SIG_SCHOOL
        UI::SameLine();
        UI::Text("\\$777(\\$ff0" + Icons::University + " \\$777School mode"+ (Meta::IsSchoolModeWhitelisted() ? (" \\$0f0"+Icons::CodeFork+" \\$777Whitelisted") : "") +")");
#endif
#if WINDOWS
        UI::Text(Icons::Windows + " \\$777Windows");
#endif
#if LINUX
        UI::Text(Icons::Linux + " \\$777Linux");
#endif
#if WINDOWS_WINE
        UI::Text(Icons::Glass + " \\$777Wine compatibility layer detected");
#endif

        UI::PushFont(Fonts::Header);
        UI::PushStyleColor(UI::Col::Separator, COLOR_VEC);
        UI::SeparatorText(COLOR_STR + PLUGIN_ICON + " \\$zServer");
        UI::PopStyleColor();
        UI::PopFont();
        if (g_serverInfo !is null) {
            UI::Text("Version \\$777" + g_serverInfo.version + " (" + g_serverInfo.deployement + ", " + g_serverInfo.gitCommit + ", " + Time::FormatString("%F", g_serverInfo.gitCommitTimestamp) + ")");
            UI::Text("Started \\$777" + Time::FormatString("%F %T", g_serverInfo.startTimestamp));
        }

        UI::PushFont(Fonts::Header);
        UI::PushStyleColor(UI::Col::Separator, COLOR_VEC);
        UI::SeparatorText(Icons::User + " Player");
        UI::PopStyleColor();
        UI::PopFont();
        if (g_connectedPlayer !is null) {
            UI::Text(g_connectedPlayer.displayName + " \\$777(" + g_connectedPlayer.accountId + ")");
            UI::Text("First connexion \\$777" + Time::FormatString("%F %X", g_connectedPlayer.firstLogonTimestamp));
            UI::Text("Connected \\$777" + Time::FormatString("%F %X", g_connectedPlayer.lastLogonTimestamp));
            UI::Text("Group \\$777" + g_connectedPlayer.group.nameWithIconColor);
        }

        UI::PushFont(Fonts::Header);
        UI::PushStyleColor(UI::Col::Separator, vec4(1, 0.24f, 0.66f, 1));
        UI::SeparatorText("\\$f39" + Icons::Heartbeat + " \\$zOpenplanet");
        UI::PopStyleColor();
        UI::PopFont();
        UI::Text("Version \\$777" + Meta::OpenplanetBuildInfo());
#if DEVELOPER
        UI::SameLine();
        UI::Text("\\$777(\\$f39" + Icons::CodeFork + " \\$777debug build)");
#endif
    }
}