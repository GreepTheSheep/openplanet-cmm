class InfoTab : Tab {
    string GetLabel() override { return Icons::InfoCircle; }
    string GetTooltip() override { return "Info"; }
    vec4 GetColor() override { return vec4(0.47f, 0.47f, 0.47f, 1); }

    string CreateBuildReportText() {
        string buildReportStr = PLUGIN_NAME + " v" + Meta::ExecutingPlugin().Version + "\n";
        buildReportStr += "Plugin build type: "+tostring(Meta::ExecutingPlugin().Type)+"\n";
        buildReportStr += "Plugin Dev build: ";
#if CMM_DEV_BUILD
        buildReportStr += "True\n";
#else
        buildReportStr += "False\n";
#endif
        buildReportStr += "OS: ";
#if WINDOWS
        buildReportStr += "Windows";
#elif LINUX
        buildReportStr += "Linux";
#endif
#if WINDOWS_WINE
        buildReportStr += " (Wine detected)";
#endif
        buildReportStr += "\n";
        buildReportStr += "Openplanet " + Meta::OpenplanetBuildInfo() + "\n";
#if DEVELOPER
        buildReportStr += "Openplanet debug build detected\n";
#endif
        buildReportStr += "Signature: ";
#if SIG_SCHOOL
        buildReportStr += "School" + (Meta::IsSchoolModeWhitelisted() ? " (Whitelisted)" : "");
#elif SIG_DEVELOPER
        buildReportStr += "Developer";
#elif SIG_REGULAR
        buildReportStr += "Regular";
#elif SIG_OFFICIAL
        buildReportStr += "Official";
#endif
        buildReportStr += "\n\n";
        buildReportStr += "Connected player: " + g_connectedPlayer.displayName + " (" + g_connectedPlayer.accountId + ")\n";
        buildReportStr += "Last logon: " + g_connectedPlayer.lastLogon + "\n";
        buildReportStr += "Group: " + g_connectedPlayer.group.name;
        buildReportStr += "\n\n";
        buildReportStr += "Server: " + Setting_BaseURL + "\n";
        buildReportStr += "Instance ID: " + g_serverInstanceId;
        buildReportStr += "\n\n";
        buildReportStr += "Report generated: " + Time::FormatString("%c", Time::Stamp);

        return buildReportStr;
    }

    void Render() override {
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
        UI::Text("\\$777(\\$0f0" + Icons::CodeFork + " \\$777School mode"+ (Meta::IsSchoolModeWhitelisted() ? (" \\$0f0"+Icons::Check+" \\$777Whitelisted") : "") +")");
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

        if (UI::GreenButton(Icons::Patreon + " \\$zSupport " + PLUGIN_NAME_SHORT)) OpenBrowserURL("https://patreon.com/Greep");
        UI::SameLine();
        if (UI::Button(Icons::DiscordAlt + " Discord")) OpenBrowserURL("https://greep.fr/#/discord");
        UI::SameLine();
        if (UI::Button(Icons::Heartbeat + " Plugin Home")) OpenBrowserURL("https://openplanet.dev/plugin/" + Meta::ExecutingPlugin().SiteID);

        UI::PushFont(Fonts::Header);
        UI::PushStyleColor(UI::Col::Separator, COLOR_VEC);
        UI::SeparatorText(ICON_COL + " Server");
        UI::PopStyleColor();
        UI::PopFont();
        UI::Text("Instance ID \\$777" + g_serverInstanceId);

        UI::PushStyleColor(UI::Col::Separator, COLOR_VEC);
        UI::SeparatorText(Icons::User + " Connected Player:");
        UI::PopStyleColor();
        UI::Text(g_connectedPlayer.displayName + " \\$777(" + g_connectedPlayer.accountId + ")");
        UI::Text("First connexion \\$777" + Time::FormatString("%F %X", g_connectedPlayer.firstLogonTimestamp));
        UI::Text("Connected \\$777" + Time::FormatString("%F %X", g_connectedPlayer.lastLogonTimestamp));
        UI::Text("Group \\$777" + g_connectedPlayer.group.nameWithIconColor);

        UI::PushFont(Fonts::Header);
        UI::PushStyleColor(UI::Col::Separator, vec4(1, 0.24f, 0.66f, 1));
        UI::SeparatorText("\\$f39" + Icons::Heartbeat + " \\$z Openplanet");
        UI::PopStyleColor();
        UI::PopFont();
        UI::Text("Version \\$777" + Meta::OpenplanetBuildInfo());
#if DEVELOPER
        UI::SameLine();
        UI::Text("\\$777(\\$f39" + Icons::CodeFork + " \\$777debug build)");
#endif

        UI::TextDisabled(Icons::Clipboard);
        UI::SetPreviousTooltip("Copy build info to clipboard for debug purposes.");
        if (UI::IsItemClicked()) IO::SetClipboard(CreateBuildReportText());
    }
}