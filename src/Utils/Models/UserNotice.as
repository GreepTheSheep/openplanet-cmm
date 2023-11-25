class UserNotice {
    bool isEnabled;
    string icon;
    string title;
    string description;

    UserNotice(const Json::Value &in json) {
        isEnabled = json["isEnabled"];
        icon = json["icon"];
        title = json["title"];
        description = json["description"];
    }
}