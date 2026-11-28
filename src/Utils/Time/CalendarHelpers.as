namespace Time {
    const array<string> monthsString = {
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
    };
    const array<string> daysString = {
        "Mo",
        "Tu",
        "We",
        "Th",
        "Fr",
        "Sa",
        "Su"
    };
    const array<int> daysInMonth = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};

    // Implements Zeller's Congruence to determine the day of week [1, 7](Mon-Sun) from the given parameters
    int DayOfWeek(int dayOfMonth, int month, int year) {
        if ((month == 1) || (month == 2))
        {
            month += 12;
            year -= 1;
        }

        int h = (dayOfMonth
            + int(Math::Floor((13 * (month + 1)) / 5.0))
            + year
            + int(Math::Floor(year / 4.0))
            - int(Math::Floor(year / 100.0))
            + int(Math::Floor(year / 400.0))) % 7;

        return int(Math::Floor(((h + 5) % 7) + 1));
    }

    bool IsLeapYear(int year) {
        if ((year % 400) == 0)
            return true;

        if ((year % 4 == 0) && ((year % 100) != 0))
            return true;

        return false;
    }

    int NumDaysInMonth(int month, int year) {
        if ((month == 2) && IsLeapYear(year))
            return 29;

        return daysInMonth[month - 1];
    }

    // Returns the number of calendar weeks spanned by month in the specified year
    int NumWeeksInMonth(int month, int year) {
        int days = NumDaysInMonth(month, year);
        int firstDay = DayOfWeek(1, month, year);

        return int(Math::Ceil((days + firstDay - 1) / 7.0));
    }

    // Returns an array containing dates as they would appear on the calendar for a given week. Populates 0 if there is no day.
    array<int> CalendarWeek(int week, int startDay, int daysInMonth) {
        array<int> res = {0,0,0,0,0,0,0};
        int startOfWeek = 7 * (week - 1) + 2 - startDay;

        if (startOfWeek >= 1)
            res[0] = startOfWeek;

        for (int i = 1; i < 7; ++i)
        {
            int day = startOfWeek + i;
            if ((day >= 1) && (day <= daysInMonth))
                res[i] = day;
        }

        return res;
    }
}