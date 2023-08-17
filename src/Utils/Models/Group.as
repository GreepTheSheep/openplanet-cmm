class Group {
    int id;
    string name;
    string color;
    array<Permission@> permissions;

    Group(const Json::Value &in json) {
        id = json["id"];
        name = json["name"];
        color = json["color"];

        for (uint i = 0; i < json["permissions"].Length; i++) {
            Permission@ perm = Permission(json["permissions"][i]);
            permissions.InsertLast(perm);
        }
    }
}