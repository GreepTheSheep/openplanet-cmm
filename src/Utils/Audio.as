namespace Audio {

    enum Sounds {
        Default,
        MatchFound,
        SquadPlayerJoined,
        SquadPlayerLeft,
        SquadPlayerMessage
    }

    dictionary MatchFoundSounds = {
        {'Default', "src/Sounds/UIEvent_ScoreProgress1.wav"},
        {'Trackmania Server Notification', "src/Sounds/UIPhaseChange.wav"}
    };

    void PlaySound(const Sounds &in sound) {

        string fileName = "src/Sounds/UIConnect_AllPlayers.wav";

        switch (sound) {
            case Sounds::MatchFound :
                MatchFoundSounds.Get(Setting_MatchFoundAudio, fileName);
                break;
            case Sounds::SquadPlayerJoined :
                fileName = "src/Sounds/UIConnect_NewPlayer.wav";
                break;
            case Sounds::SquadPlayerLeft :
                fileName = "src/Sounds/UIPopUp_Left.wav";
                break;
            case Sounds::SquadPlayerMessage :
                fileName = "src/Sounds/UIConnect_AllPlayers.wav";
                break;
            default:
                fileName = "src/Sounds/UIConnect_AllPlayers.wav";
        }

        Sample@ sample = LoadSample(fileName);
        if (sample is null) {
            Log::Error("Audio sample could not be casted: "+ fileName);
            return;
        }
        Play(sample, Setting_NotificationsVolume / 100.0f);
    }
}