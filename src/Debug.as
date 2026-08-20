#if CMM_DEV_BUILD || SIG_DEVELOPER
[SettingsTab name="Debug" icon="FileCodeO"]
void RenderDebugSettingsTab() {
    if (stampServerRetry - Time::Stamp >= 0) UI::TextDisabled(Icons::Refresh + " Next server health check in " + Time::FormatString("%Ss", stampServerRetry - Time::Stamp));
    else UI::TextDisabled(Icons::Refresh + " A server health check is performed every minute" + (!isServerAlive ? ", but it appears there is a major error in the data being returned" : "") + ".");
}
#endif