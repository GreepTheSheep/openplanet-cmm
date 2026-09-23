namespace Fonts {
    UI::Font@ Regular;
    UI::Font@ Bold;
    UI::Font@ Header;
    UI::Font@ SubHeader;
    UI::Font@ UserNoticeIcon;

    void Load() {
        @Regular = UI::LoadFont("DroidSans.ttf");
        @Bold = UI::LoadFont("DroidSans-Bold.ttf");
        @Header = UI::LoadFont("DroidSans-Bold.ttf", 24);
        @SubHeader = UI::LoadFont("DroidSans-Bold.ttf", 20);
        @UserNoticeIcon = UI::LoadFont("DroidSans.ttf", 32);
    }
}