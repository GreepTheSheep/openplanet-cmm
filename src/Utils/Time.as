namespace Time {
    string displayTimeLeft(const int64 &in timestamp = Time::Stamp, const bool &in fullText = false) {
        int64 timestampLeft = timestamp - Time::Stamp;
        if (timestampLeft == 0) return "00:00:00";
        if (timestampLeft < 0) return ""; // Invalid timestamp, do not parse!
        Time::Info timeLeft = Time::Parse(timestampLeft);
        string timeLeftString = "";
        if (timeLeft.Month > 1) timeLeftString += tostring(timeLeft.Month) + (fullText ? " months, " : "m, ");
        if (timeLeft.Day > 1) timeLeftString += tostring(timeLeft.Day) + (fullText ? " days and " : "d ");
        timeLeftString += Time::FormatString("%T", timestampLeft);
        return timeLeftString;
    }
}