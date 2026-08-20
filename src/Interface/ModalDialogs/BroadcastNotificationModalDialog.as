class BroadcastNotificationModalDialog : ModalDialog
{
    string notificationMessage;

    BroadcastNotificationModalDialog(const string &in message)
    {
        super(ICON_COL + " " + PLUGIN_NAME + " \\$zMessage from admins###BroadcastNotificationModalDialog");
        notificationMessage = message;
        m_size = vec2(500, 170);
    }

    void RenderDialog() override
    {
        UI::PushFont(Fonts::Header);
        UI::Text("Message from admins of " + PLUGIN_NAME);
        UI::PopFont();
        UI::NewLine();
        UI::Markdown(notificationMessage);
        UI::NewLine();
        if (UI::Button(Icons::Times + " Close")) Close();
    }
}