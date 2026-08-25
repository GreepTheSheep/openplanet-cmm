namespace Fonts {
    UI::Font@ Bold;
    UI::Font@ Header;
    UI::Font@ UserNoticeIcon;

    void Load() {
        @Bold = UI::LoadFont("DroidSans-Bold.ttf");
        @Header = UI::LoadFont("DroidSans.ttf", 24);
        @UserNoticeIcon = UI::LoadFont("DroidSans.ttf", 32);
    }
}