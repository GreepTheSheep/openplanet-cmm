class MainWindow : Window {
    Tab@ m_homePageTab;
    // Tab@ m_YourProfileTab;

    MainWindow(){
        @m_homePageTab = HomePageTab();
        AddTab(m_homePageTab);
    }

    string GetWindowId() override { return "BMMMainWindow"; }

}