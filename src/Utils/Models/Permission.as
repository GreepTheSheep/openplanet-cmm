class Permission {
    int id;
    string name;
    string description;

    Permission(const Json::Value &in json) {
        id = json["id"];
        name = json["name"];
        if (json.HasKey("description") && json["description"].GetType() != Json::Type::Null) description = json["description"];
    }
}