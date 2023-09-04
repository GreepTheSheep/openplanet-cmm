class Squad {
    string name;
    Player@ ownerPlayer;
    array<Player@> players;
    int inviteCode;

    Squad(const Json::Value &in json) {
        name = json["name"];
        @ownerPlayer = Player(json["ownerPlayer"]);
        for (uint p = 0; p < json["players"].Length; p++){
            Player@ player = Player(json["players"][p]);
            players.InsertLast(player);
        }
        inviteCode = json["inviteCode"];
    }
}