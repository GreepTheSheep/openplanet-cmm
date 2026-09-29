class Squad {
    string name;
    string ownerPlayer;
    array<Player@> players;
    int inviteCode;
    array<SquadMessage@> messages;
    int matchmakingTypeId = -1;
    bool isSearching = false;
    dictionary readyStates;

    Squad(const Json::Value &in json) {
        name = json["name"];
        ownerPlayer = json["ownerPlayer"];
        for (uint p = 0; p < json["players"].Length; p++){
            Player@ player = Player(json["players"][p]);
            players.InsertLast(player);
        }
        inviteCode = json["inviteCode"];
        for (uint m = 0; m < json["messages"].Length; m++){
            SquadMessage@ msg = SquadMessage(json["messages"][m]);
            messages.InsertLast(msg);
        }
        readyStates = dictionary();
        if (json.HasKey("matchmakingTypeId") && json["matchmakingTypeId"].GetType() == Json::Type::Number) matchmakingTypeId = json["matchmakingTypeId"];
    }

    bool isPlayerReady(const string &in accountId) {
        bool ready = false;
        if (readyStates.Get(accountId, ready)) return ready;
        return false;
    }
}