class Permission {
    int id;
    string name;
    string description;

    Permission(const Json::Value &in json) {
        id = json["id"];
        name = json["name"];
        description = json["description"];
    }
}