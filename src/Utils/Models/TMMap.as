class TMMap {
    string UId;
    string Name;
    string Author;
    string AuthorNickname;

    TMMap(const Json::Value &in json) {
        UId = json["UId"];
        Name = json["Name"];
        Author = json["Author"];
        AuthorNickname = json["AuthorNickname"];
    }
}