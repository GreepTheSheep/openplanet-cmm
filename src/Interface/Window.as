class Window {
    bool isOpened = false;

    array<Tab@> tabs;
    Tab@ activeTab;
    Tab@ selectedTab;
    Tab@ c_lastActiveTab;
    // Tab@ m_YourProfileTab;

    string GetWindowId() { return "YAMMDefaultWindow"; }
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

        UI::PushStyleColor(UI::Col::WindowBg,vec4(.1,.1,.1,1));
        UI::SetNextWindowSize(520,360, UI::Cond::Once);
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
        UI::PopStyleColor(1);
    }

}