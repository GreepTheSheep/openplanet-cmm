namespace UI {
    // Date picker only
    Time::Info DatePicker(const string &in label, Time::Info time, const bool &in disabled = false) {
        string timeInfoString = Time::InfoToLongString(time, Time::InfoToLongStringContents::DateOnly);

        bool hiddenLabel = label.SubStr(0, 2) == "##";
        string myLabel = (hiddenLabel) ? label.SubStr(2) : label;

        SetNextWindowSize(274, 301);
        if (BeginCombo(label, timeInfoString)) {
            BeginDisabled(disabled);

            time = DatePickerContent(myLabel, time);

            EndDisabled();
            EndCombo();
        }

        return time;
    }

    // Time picker only
    Time::Info TimePicker(const string &in label, Time::Info time, const bool &in disabled = false, const uint &in minuteSteps = 1, const bool &in canEditSeconds = true, const uint &in secondsSteps = 1, const bool &in displayHeader = true) {
        string timeInfoString = Time::InfoToLongString(time, Time::InfoToLongStringContents::TimeOnly, canEditSeconds);

        bool hiddenLabel = label.SubStr(0, 2) == "##";
        string myLabel = (hiddenLabel) ? label.SubStr(2) : label;

        SetNextWindowSize(274, 301);
        if (BeginCombo(label, timeInfoString)) {
            BeginDisabled(disabled);

            time = TimePickerContent(myLabel, time, minuteSteps, canEditSeconds, secondsSteps, displayHeader);

            EndDisabled();
            EndCombo();
        }

        return time;
    }

    // Date and Time picker
    Time::Info DateTimePicker(const string &in label, Time::Info time, const bool &in disabled = false, const uint &in minuteSteps = 1, const bool &in canEditSeconds = true, const uint &in secondsSteps = 1, const bool &in timePickerDisplayHeader = true) {
        string timeInfoString = Time::InfoToLongString(time, Time::InfoToLongStringContents::DateAndTime, canEditSeconds);

        bool hiddenLabel = label.SubStr(label.IndexOf("##"), 2) == "##";
        string myLabel = (hiddenLabel) ? label.SubStr(label.IndexOf("##") + 2) : label;

        SetNextWindowSize(274, 301);
        if (BeginCombo(label, timeInfoString)) {
            BeginDisabled(disabled);

            time = DatePickerContent(myLabel+"_combined_datePicker", time);
            time = TimePickerContent(myLabel+"_combined_timePicker", time, minuteSteps, canEditSeconds, secondsSteps, timePickerDisplayHeader);

            EndDisabled();
            EndCombo();
        }

        return time;
    }

    // Content of the Date Picker Combo
    Time::Info DatePickerContent(const string &in label, Time::Info time) {
        Time::Info today = Time::Parse(Time::Stamp);
        int monthIdx = time.Month - 1;
        int year = time.Year;

        PushItemWidth(GetContentRegionAvail().x * 0.5f);

        time.Month = ComboBox("##CmbMonth_" + label, Time::monthsString, monthIdx) + 1;

        PopItemWidth();
        SameLine();
        PushItemWidth(GetContentRegionAvail().x);

        year = InputInt("##IntYear_" + label, year);
        if (time.Year != year) {
            time.Year = Math::Clamp(year, 1970, 3000);
        }

        PopItemWidth();

        const float contentWidth = GetContentRegionAvail().x;
        const float arrowSize = GetFrameHeightWithSpacing();
        const float arrowButtonWidth = arrowSize * 2.0f + GetStyleVarVec2(StyleVar::ItemSpacing).x;
        const float bulletSize = arrowSize - 12.0f;
        const float bulletButtonWidth = bulletSize + GetStyleVarVec2(StyleVar::ItemSpacing).x;
        const float combinedWidth = arrowButtonWidth + bulletButtonWidth;
        const float offset = (contentWidth - combinedWidth) * 0.5f;

        SetCursorPosX(GetCursorPos().x + offset);
        PushStyleVar(StyleVar::FrameRounding, 20.0f);
        PushStyleColor(Col::Button, vec4(0.0f, 0.0f, 0.0f, 0.0f));
        PushStyleColor(Col::Border, vec4(0.0f, 0.0f, 0.0f, 0.0f));
        BeginDisabled(Time::IsMinDate(time));

        if (Button(Icons::ArrowLeft)) {
            time = Time::PreviousMonth(time);
        }

        EndDisabled();
        PopStyleColor(2);
        SameLine();
        PushStyleColor(Col::Button, vec4(0.0f, 0.0f, 0.0f, 0.0f));
        SetCursorPosX(GetCursorPos().x + 2.0f);

        if (Button(Icons::Circle)) {
            time.Month = today.Month;
            time.Year = today.Year;
        }

        PopStyleColor();
        SameLine();
        PushStyleColor(Col::Button, vec4(0.0f, 0.0f, 0.0f, 0.0f));
        PushStyleColor(Col::Border, vec4(0.0f, 0.0f, 0.0f, 0.0f));
        BeginDisabled(Time::IsMaxDate(time));

        if (Button(Icons::ArrowRight)) {
            time = Time::NextMonth(time);
        }

        EndDisabled();
        PopStyleColor(2);
        PopStyleVar();

        if (BeginTable("##Table_" + label, 7, TableFlags::BordersOuter | TableFlags::SizingFixedFit | TableFlags::NoHostExtendX, vec2(GetContentRegionAvail().x, 0.0f))) {
            for (uint dayIndex = 0; dayIndex < Time::daysString.Length; dayIndex++) {
                TableSetupColumn(Time::daysString[dayIndex], TableColumnFlags::WidthFixed | TableColumnFlags::NoHeaderWidth | TableColumnFlags::NoSort, 30.0f);
            }

            PushStyleColor(Col::HeaderHovered, GetStyleColor(Col::TableHeaderBg));
            PushStyleColor(Col::HeaderActive, GetStyleColor(Col::TableHeaderBg));
            TableHeadersRow();
            PopStyleColor(2);

            TableNextRow();
            TableSetColumnIndex(0);

            int month = monthIdx + 1;
            int firstDayOfMonth = Time::DayOfWeek(1, month, year);
            int numDaysInMonth = Time::NumDaysInMonth(month, year);
            int numWeeksInMonth = Time::NumWeeksInMonth(month, year);

            for (int i = 1; i <= numWeeksInMonth; i++) {
                for (uint dayIndex = 0; dayIndex < Time::CalendarWeek(i, firstDayOfMonth, numDaysInMonth).Length; dayIndex++) {
                    int day = Time::CalendarWeek(i, firstDayOfMonth, numDaysInMonth)[dayIndex];
                    if (day != 0) {
                        PushStyleVar(StyleVar::FrameRounding, 20.0f);

                        const bool selected = day == time.Day;
                        if (!selected) {
                            PushStyleColor(Col::Button, vec4(0.0f, 0.0f, 0.0f, 0.0f));
                            PushStyleColor(Col::Border, vec4(0.0f, 0.0f, 0.0f, 0.0f));
                        }

                        if (Button(tostring(day), vec2(GetContentRegionAvail().x, GetTextLineHeightWithSpacing() + 5.0f))) {
                            time.Day = day;
                            time.Month = month;
                            time.Year = year;
                        }

                        if (!selected) PopStyleColor(2);

                        PopStyleVar();
                    }

                    if (day != numDaysInMonth)
                        TableNextColumn();
                }
            }

            EndTable();
        }

        return time;
    }

    // Content of the Time Picker Combo
    Time::Info TimePickerContent(const string &in label, Time::Info time, const uint &in minuteSteps = 1, const bool &in canEditSeconds = true, const uint &in secondsSteps = 1, const bool &in displayHeader = true) {

        // All widths must be calculated based on the total width of the line,
        // excluding the two ":" characters and the spaces from SameLine().
        const float totalWidth = GetContentRegionAvail().x;
        const float spacing = GetStyleVarVec2(StyleVar::ItemSpacing).x;
        const float colonWidth = MeasureString(":", null, GetFontSize()).x;
        const float comboWidth = canEditSeconds
            ? (totalWidth - 2.0f * colonWidth - 4.0f * spacing) / 3.0f
            : (totalWidth - colonWidth - 2.0f * spacing) / 2.0f;

        if (displayHeader) {
            const float startX = GetCursorPos().x;
            const float step = comboWidth + colonWidth + 2.0f * spacing;

            string headerLabel = "Hour";
            const float hourLabelWidth = MeasureString(headerLabel, null, GetFontSize()).x;
            SetCursorPosX(startX + (comboWidth - hourLabelWidth) * 0.5f);
            Text(headerLabel);

            headerLabel = "Minute";
            const float minuteLabelWidth = MeasureString(headerLabel, null, GetFontSize()).x;
            SameLine();
            SetCursorPosX(startX + step + (comboWidth - minuteLabelWidth) * 0.5f);
            Text(headerLabel);

            if (canEditSeconds) {
                headerLabel = "Second";
                const float secondLabelWidth = MeasureString(headerLabel, null, GetFontSize()).x;
                SameLine();
                SetCursorPosX(startX + 2.0f * step + (comboWidth - secondLabelWidth) * 0.5f);
                Text(headerLabel);
            }
        }

        PushItemWidth(comboWidth);

        if (BeginCombo("##CmbHour_" + label, tostring(time.Hour), ComboFlags::NoArrowButton)) {
            for (uint h = 0; h < 24; h++) {
                bool selected = int(h) == time.Hour;
                if (Selectable(tostring(h), selected)) {
                    time.Hour = h;
                }
                if (selected) SetItemDefaultFocus();
            }
            EndCombo();
        }
        if (time.Hour < 0) time.Hour = 0;
        if (time.Hour > 23) time.Hour = 23;

        SameLine();
        Text(":");
        SameLine();

        if (BeginCombo("##CmbMinute_" + label, tostring(time.Minute), ComboFlags::NoArrowButton)) {
            for (uint m = 0; m < 59; m = m + minuteSteps) {
                bool selected = int(m) == time.Minute;
                if (Selectable(tostring(m), selected)) {
                    time.Minute = m;
                }
                if (selected) SetItemDefaultFocus();
            }
            EndCombo();
        }
        if (time.Minute < 0) time.Minute = 0;
        if (time.Minute > 59) time.Minute = 59;

        if (canEditSeconds) {
            SameLine();
            Text(":");
            SameLine();

            if (BeginCombo("##CmbSecond_" + label, tostring(time.Second), ComboFlags::NoArrowButton)) {
                for (uint s = 0; s < 59; s = s + secondsSteps) {
                    bool selected = int(s) == time.Second;
                    if (Selectable(tostring(s), selected)) {
                        time.Second = s;
                    }
                    if (selected) SetItemDefaultFocus();
                }
                EndCombo();
            }
            if (time.Second < 0) time.Second = 0;
            if (time.Second > 59) time.Second = 59;
        } else time.Second = 0;

        PopItemWidth();

        UI::Separator();
        UI::Text("In your timezone: " + Time::FormatString("%Z (%z)", Time::ParseFormatInfo(time)));
        UI::Text(Time::InfoToLongString(time, Time::InfoToLongStringContents::DateAndTime, false, true));

        return time;
    }
}