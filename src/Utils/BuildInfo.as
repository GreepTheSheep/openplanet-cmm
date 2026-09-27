namespace CMMBuildInfo {
    string CreateBuildReportText() {
        string header = PLUGIN_NAME + " v" + Meta::ExecutingPlugin().Version;
        array<string> headerDelimiter;
        for (int i = 0; i < header.Length; i++) headerDelimiter.InsertLast("=");
        string buildReportStr = header + "\n" + Text::Join(headerDelimiter,"") + "\n\n";
        buildReportStr += "* BuildType: "+tostring(Meta::ExecutingPlugin().Type)+"\n";
        buildReportStr += "* DevBuild: ";
#if CMM_DEV_BUILD
        buildReportStr += "True";
#else
        buildReportStr += "False";
#endif
        buildReportStr += "\n\n";

        string openplanetHeader = "Openplanet";
        array<string> openplanetHeaderDelimiter;
        for (int i = 0; i < openplanetHeader.Length; i++) openplanetHeaderDelimiter.InsertLast("-");
        buildReportStr += openplanetHeader + "\n" + Text::Join(openplanetHeaderDelimiter,"") + "\n\n";
        buildReportStr += "* OpenplanetBuild: " + Meta::OpenplanetBuildInfo() + "\n";
        buildReportStr += "* Arch: ";
#if MANIA64
        buildReportStr += "64bit";
#elif MANIA32
        buildReportStr += "32bit";
#else
        buildReportStr += "unknown";
#endif
        buildReportStr += "\n";
        buildReportStr += "* Signature: ";
#if SIG_DEVELOPER
        buildReportStr += "Developer";
#elif SIG_SCHOOL
        buildReportStr += "School" + (Meta::IsSchoolModeWhitelisted() ? " (Whitelisted)" : "");
#elif SIG_REGULAR
        buildReportStr += "Regular";
#elif SIG_OFFICIAL
        buildReportStr += "Official";
#else
        buildReportStr += "unknown";
#endif
        buildReportStr += "\n";
        buildReportStr += "* SchoolMode: ";
#if SIG_SCHOOL
        buildReportStr += "True" + (Meta::IsSchoolModeWhitelisted() ? " (Whitelisted)" : " (NOT Whitelisted)");
#else
        buildReportStr += "False";
#endif
        buildReportStr += "\n";
        buildReportStr += "* OS: ";
#if WINDOWS
        buildReportStr += "Windows";
#elif LINUX
        buildReportStr += "Linux";
#else
        buildReportStr += "unknown";
#endif
#if WINDOWS_WINE
        buildReportStr += " (Wine detected)";
#endif
        buildReportStr += "\n";
        buildReportStr += "* DebugBuild: ";
#if DEVELOPER
        buildReportStr += "True";
#else
        buildReportStr += "False";
#endif
        buildReportStr += "\n\n";

        string playerHeader = "Player";
        array<string> playerHeaderDelimiter;
        for (int i = 0; i < playerHeader.Length; i++) playerHeaderDelimiter.InsertLast("-");
        buildReportStr += playerHeader + "\n" + Text::Join(playerHeaderDelimiter,"") + "\n\n";
        buildReportStr += "* Name: " + g_connectedPlayer.displayName + "\n";
        buildReportStr += "* AccountId: " + g_connectedPlayer.accountId + "\n";
        buildReportStr += "* FirstLogon: " + Time::FormatString("%F %X", g_connectedPlayer.firstLogonTimestamp) + "\n";
        buildReportStr += "* Connected: " + Time::FormatString("%F %X", g_connectedPlayer.lastLogonTimestamp) + "\n";
        buildReportStr += "* Group: " + g_connectedPlayer.group.name;
        buildReportStr += "\n\n";

        string serverHeader = "Server";
        array<string> serverHeaderDelimiter;
        for (int i = 0; i < serverHeader.Length; i++) serverHeaderDelimiter.InsertLast("-");
        buildReportStr += serverHeader + "\n" + Text::Join(serverHeaderDelimiter,"") + "\n\n";
        buildReportStr += "* URL: " + Setting_BaseURL + "\n";
        if (g_serverInfo !is null) {
                buildReportStr += "* Name: " + g_serverInfo.name + "\n";
                buildReportStr += "* Version: " + g_serverInfo.version + "\n";
                buildReportStr += "* StartTime: " + Time::FormatString("%F %X", g_serverInfo.startTimestamp) + "\n";
                buildReportStr += "* Commit: " + g_serverInfo.gitCommit + "\n";
                buildReportStr += "* CommitTime: " + Time::FormatString("%F %X", g_serverInfo.gitCommitTimestamp) + "\n";
                buildReportStr += "* Environ: " + g_serverInfo.nodeEnv + "\n";
                buildReportStr += "* Dev: " + tostring(g_serverInfo.isDev);
        }

        return buildReportStr;
    }
}