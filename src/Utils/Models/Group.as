class Group {
    int id;
    string name;
    string color;
    string nameWithColor;
    array<Permission@> permissions;

    Group(const Json::Value &in json) {
        id = json["id"];
        name = json["name"];
        if (json.HasKey("color") && json["color"].GetType() != Json::Type::Null) color = json["color"];

        nameWithColor = (color.Length > 0 ? ("\\$" + color) : "") + name;

        for (uint i = 0; i < json["permissions"].Length; i++) {
            Permission@ perm = Permission(json["permissions"][i]);
            permissions.InsertLast(perm);
        }
    }
}