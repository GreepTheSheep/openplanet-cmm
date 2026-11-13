namespace Time {
    /*
     * Parses a time from a `Time::Info` class into a ISO8601 Date.
     * The timeInfo class should be set in UTC format
    */
    string FormatInfoISO(const Info &in timeInfo) {
        // We need to add zeros prefixes if any numbers are below 10 for Month, Day, Hour, Minute and Second
        string monthStr = timeInfo.Month < 10 ? ("0" + timeInfo.Month) : tostring(timeInfo.Month);
        string dayStr = timeInfo.Day < 10 ? ("0" + timeInfo.Day) : tostring(timeInfo.Day);
        string hourStr = timeInfo.Hour < 10 ? ("0" + timeInfo.Hour) : tostring(timeInfo.Hour);
        string minuteStr = timeInfo.Minute < 10 ? ("0" + timeInfo.Minute) : tostring(timeInfo.Minute);
        string secondStr = timeInfo.Second < 10 ? ("0" + timeInfo.Second) : tostring(timeInfo.Second);

        return tostring(timeInfo.Year) + "-" + monthStr + "-" + dayStr + "T" + hourStr + ":" + minuteStr + ":" + secondStr + "Z";
    }

    /*
     * Parses a time from a `Time::Info` class into a timestamp.
     * The timeInfo class should be set in UTC format.
     * Returns 0 if the date parsing fails
    */
    int64 ParseFormatInfo(const Info &in timeInfo) {
        // Method: Use FormatInfoISO
        // Then parse with ParseFormatString

        try {
            string dateISO = FormatInfoISO(timeInfo);
            return ParseFormatString("%FT%TZ", dateISO);
        } catch {
            Log::Error("Time::ParseFormatInfo : " + getExceptionInfo());
            return 0;
        }
    }

    enum InfoToLongStringContents {
        DateOnly,
        TimeOnly,
        DateAndTime
    }

    string InfoToLongString(const Info &in time, const InfoToLongStringContents content = InfoToLongStringContents::DateAndTime, const bool &in timeIncludeSeconds = true, const bool &in toTimezone = false) {

        // We need to add zeros prefixes if any numbers are below 10 for Month, Day, Hour, Minute and Second
        //string monthStr = time.Month < 10 ? ("0" + time.Month) : tostring(time.Month);
        string yearStr = tostring(time.Year);
        string monthStr = monthsString[time.Month - 1];
        string dayStr = time.Day < 10 ? ("0" + time.Day) : tostring(time.Day);
        string hourStr = time.Hour < 10 ? ("0" + time.Hour) : tostring(time.Hour);
        string minuteStr = time.Minute < 10 ? ("0" + time.Minute) : tostring(time.Minute);
        string secondStr = time.Second < 10 ? ("0" + time.Second) : tostring(time.Second);

        if (toTimezone) {
            int64 infoStamp = ParseFormatInfo(time);
            yearStr = FormatString("%Y", infoStamp);
            monthStr = FormatString("%B", infoStamp);
            dayStr = FormatString("%d", infoStamp);
            hourStr = FormatString("%H", infoStamp);
            minuteStr = FormatString("%M", infoStamp);
            secondStr = FormatString("%S", infoStamp);
        }

        switch (content) {
            case InfoToLongStringContents::DateOnly:
                return dayStr+" "+monthStr+" "+yearStr;
            case InfoToLongStringContents::TimeOnly:
                return hourStr+":"+minuteStr+(timeIncludeSeconds ? ":"+secondStr : "");
            default:
                return dayStr+" "+monthStr+" "+yearStr+" "+hourStr+":"+minuteStr+(timeIncludeSeconds ? ":"+secondStr : "");
        }
    }

    Info PreviousMonth(Info timePoint) {
        if (timePoint.Month == 1) {
            timePoint.Month = 12;
            timePoint.Day = Math::Min(timePoint.Day, NumDaysInMonth(timePoint.Month, --timePoint.Year));
            return timePoint;
        }

        timePoint.Day = Math::Min(timePoint.Day, NumDaysInMonth(--timePoint.Month, timePoint.Year));
        return timePoint;
    }

    Info NextMonth(Info timePoint) {
        if (timePoint.Month == 12) {
            timePoint.Month = 1;
            timePoint.Day = Math::Min(timePoint.Day, NumDaysInMonth(timePoint.Month, ++timePoint.Year));
            return timePoint;
        }

        timePoint.Day = Math::Min(timePoint.Day, NumDaysInMonth(++timePoint.Month, timePoint.Year));
        return timePoint;
    }

    bool IsMinDate(const Info &in timePoint) {
        return (timePoint.Month == 1) && (timePoint.Year == 1970);
    }

    bool IsMaxDate(const Info &in timePoint) {
        return (timePoint.Month == 12) && (timePoint.Year == 3000);
    }
}