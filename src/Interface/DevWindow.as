class DevWindow : Window {

    DevWindow(){
        AddTab(ConnectedPlayersDevTab());
        AddTab(AllPlayersDevTab());
        AddTab(GroupsDevTab());
        AddTab(NoticeDevTab());
        AddTab(MMTypeDevTab());
    }

    string GetWindowId() override { return "YAMMDevWindow"; }
    string GetWindowName() override { return COLOR_STR + Icons::Code + "\\$z " + PLUGIN_NAME + " (Superadmin interface)"; }

}