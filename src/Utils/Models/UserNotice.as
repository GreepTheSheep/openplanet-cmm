class UserNotice {
    bool isEnabled;
    string title;
    string description;

    UserNotice(const Json::Value &in json) {
        isEnabled = json["isEnabled"];
        title = json["title"];
        description = json["description"];
    }
}