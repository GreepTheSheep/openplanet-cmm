class Window {
    bool isOpened = false;

    array<Tab@> tabs;
    Tab@ activeTab;
    Tab@ selectedTab;
    Tab@ c_lastActiveTab;

    int MinWidth() { return 550; }
    int MinHeight() { return 520; }
    int MaxWidth() { return 7860; }
    int MaxHeight() { return 2160; }

    string GetWindowId() { return PLUGIN_NAME_SHORT+"DefaultWindow"; }
    string GetWindowName() { return ICON_COL + PLUGIN_NAME; }

    void AddTab(Tab@ tab, bool select = false, int index = -1){
        if (index == -1) tabs.InsertLast(tab);
        else tabs.InsertAt(index, tab);
        if (select) {
            @activeTab = tab;
        }
    }

    void RemoveTab(Tab@ tab){
        tabs.RemoveAt(tabs.FindByRef(tab));
    }

    void RenderHeader() {}
    void RenderFooter() {}

    void Render(){
        if(!isOpened) return;

        UI::SetNextWindowSize(MinWidth(),MinHeight(), UI::Cond::Once);
        UI::SetNextWindowSizeConstraints(MinWidth(),MinHeight(),MaxWidth(),MaxHeight()); // Set min and max window size
        if(UI::Begin(GetWindowName()+"###"+GetWindowId(), isOpened)){
            RenderHeader();
            // Push the last active tab style so that the separator line is colored (this is drawn in BeginTabBar)
            auto lastActiveTab = c_lastActiveTab;
            if (lastActiveTab !is null) {
                lastActiveTab.PushTabStyle();
            }
            UI::BeginTabBar("Tabs");

            for(uint i = 0; i < tabs.Length; i++){
                auto tab = tabs[i];
                if (!tab.IsVisible()) continue;

                UI::PushID(tab);

                int flags = 0;
                if (tab is activeTab) {
                    flags |= UI::TabItemFlags::SetSelected;
                    if (!tab.GetLabel().Contains("Loading")) @activeTab = null;
                }

                tab.PushTabStyle();

                if (tab.CanClose()){
                    bool open = true;
                    bool beginTabClosable = UI::BeginTabItem(tab.GetLabel()+(tab.GetTooltip().Length > 0 ? "###"+tab.GetTooltip() : ""), open, flags);
                    if (tab.GetTooltip().Length > 0) UI::SetPreviousTooltip(tab.GetTooltip());
                    if (beginTabClosable){
                        @c_lastActiveTab = tab;

                        UI::BeginChild("Tab", vec2(UI::GetWindowSize().x - 12, UI::GetWindowSize().y - UI::GetCursorPos().y - 38));
                        @selectedTab = tab;
                        tab.Render();
                        UI::EndChild();

                        UI::EndTabItem();
                    }
                    if (!open){
                        tabs.RemoveAt(i--);
                    }
                } else {
                    bool beginTab = UI::BeginTabItem(tab.GetLabel()+(tab.GetTooltip().Length > 0 ? "###"+tab.GetTooltip() : ""), flags);
                    if (tab.GetTooltip().Length > 0) UI::SetPreviousTooltip(tab.GetTooltip());
                    if (beginTab){
                        @c_lastActiveTab = tab;

                        UI::BeginChild("Tab", vec2(UI::GetWindowSize().x - 12, UI::GetWindowSize().y - UI::GetCursorPos().y - 38));
                        @selectedTab = tab;
                        tab.Render();
                        UI::EndChild();

                        UI::EndTabItem();
                    }
                }

                tab.PopTabStyle();

                UI::PopID();

            }

            UI::EndTabBar();

            RenderFooter();

            // Pop the tab style (for the separator line) only after EndTabBar, to satisfy the stack unroller
            if (lastActiveTab !is null) {
                lastActiveTab.PopTabStyle();
            }
        }
        UI::End();
    }

}