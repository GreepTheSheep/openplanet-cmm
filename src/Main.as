void Main()
{
    if (!CheckServer()) return;
    await(startnew(Auth::Login));
}

void OnDisabled() {
    Auth::Logoff();
}
void OnDestroyed() {
    Auth::Logoff();
}


bool CheckServer()
{
    Json::Value@ res = API::GetAsync(Setting_BaseURL);

    if (res.GetType() == Json::Type::Null) {
        Log::Error("Server seems not responding.\nThe plugin will not load.");
        throw("Server seems not responding");
    } else if (res.GetType() == Json::Type::Object) {
        return true;
    }
    return false;
}