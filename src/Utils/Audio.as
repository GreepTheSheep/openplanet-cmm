namespace Audio {

    enum Sounds {
        Default,
        MatchFound
    }

    void PlaySound(const Sounds &in sound, int volumePercent = 50) {

        string fileName = "src/Sounds/UIConnect_AllPlayers.wav";

        switch (sound) {
            case Sounds::MatchFound :
                fileName = "src/Sounds/UIEvent_ScoreProgress1.wav";
                break;
            default:
                fileName = "src/Sounds/UIConnect_AllPlayers.wav";
        }

        Sample@ sample = LoadSample(fileName);
        if (sample is null) {
            Log::Error("Audio sample could not be casted: "+ fileName);
            return;
        }
        Play(sample, volumePercent / 100.0f);
    }
}