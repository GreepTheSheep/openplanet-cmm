namespace Fonts {
    UI::Font@ Header;
    UI::Font@ UserNoticeIcon;

    void Load() {
        @Header = UI::LoadFont("DroidSans.ttf", 24);
        @UserNoticeIcon = UI::LoadFont("DroidSans.ttf", 32);
    }
}