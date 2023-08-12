namespace Log
{
    void Log(const string &in message, bool showNotification = false)
    {
        print(message);
        if (showNotification)
        {
            UI::ShowNotification(PLUGIN_NAME, message);
        }
    }

    void Trace(const string &in message, bool showNotification = false)
    {
        trace(message);
        if (showNotification)
        {
            UI::ShowNotification(PLUGIN_NAME, message);
        }
    }

    void Warn(const string &in message, bool showNotification = Meta::IsDeveloperMode())
    {
        warn(message);
        if (showNotification)
        {
            vec4 color = UI::HSV(0.11, 1.0, 1.0);
            UI::ShowNotification(Icons::Kenney::ExclamationCircle + " " + PLUGIN_NAME + " - Warning", message, color, 5000);
        }
    }

    void Error(const string &in message, bool showNotification = Meta::IsDeveloperMode())
    {
        error(message);
        if (showNotification)
        {
            vec4 color = UI::HSV(1.0, 1.0, 1.0);
            UI::ShowNotification(Icons::Kenney::TimesCircle + " " + PLUGIN_NAME + " - Error", message, color, 8000);
        }
    }
}