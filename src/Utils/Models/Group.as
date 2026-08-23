class Group {
    int id;
    string name;
    string color;
    string icon;
    string nameWithColor;
    string iconWithColor;
    string nameWithIconColor;
    array<Permission@> permissions;

    Group(const Json::Value &in json) {
        id = json["id"];
        name = json["name"];
        if (json.HasKey("color") && json["color"].GetType() != Json::Type::Null) color = json["color"];
        if (json.HasKey("icon") && json["icon"].GetType() != Json::Type::Null) icon = json["icon"];

        nameWithColor = (color.Length > 0 ? ("\\$" + color) : "") + name;
        iconWithColor = (color.Length > 0 ? ("\\$" + color) : "") + (icon.Length > 0 ? icon : "");
        nameWithIconColor = (iconWithColor.Length > 0 ? (iconWithColor + " ") : "") + nameWithColor;

        if (json.HasKey("permissions") && json["permissions"].GetType() == Json::Type::Array) {
            for (uint i = 0; i < json["permissions"].Length; i++) {
                Permission@ perm = Permission(json["permissions"][i]);
                permissions.InsertLast(perm);
            }
        }
    }
}