class DevWindow : Window {

    DevWindow(){
        AddTab(ConnectedPlayersDevTab());
        AddTab(AllPlayersDevTab());
        AddTab(GroupsDevTab());
        AddTab(NoticeDevTab());
        AddTab(MMTypeDevTab());
    }

    string GetWindowId() override { return PLUGIN_NAME_SHORT+"DevWindow"; }
    string GetWindowName() override { return COLOR_STR + Icons::Code + "\\$z " + PLUGIN_NAME + " (Admin interface)"; }

}