class MatchTeam {
    string name;
    string colorTM;
    array<Player@> players;

    MatchTeam(const Json::Value &in json) {
        name = json["name"];
        colorTM = json["colorTM"];
        for (uint p = 0; p < json["players"].Length; p++){
            Player@ player = Player(json["players"][p]);
            players.InsertLast(player);
        }
    }
}