class DevEndSeasonConfirmationModalDialog : ModalDialog
{
    MatchmakingType@ matchmakingTypeWithSeasonToEnd;

    DevEndSeasonConfirmationModalDialog(MatchmakingType@ matchmakingType)
    {
        super(Icons::TimesCircle + " End season###DevEndSeaosnModalDialog");
        @matchmakingTypeWithSeasonToEnd = matchmakingType;
        m_size = vec2(500, 180);
    }

    void EndSeasonAsync() {
        Json::Value@ postJson = Json::Object();
        postJson["seasonId"] = matchmakingTypeWithSeasonToEnd.season.id;

        Json::Value@ resPost = API::PostAsync(Setting_BaseURL+"/admin/season/end", Json::Write(postJson));
        @matchmakingTypeWithSeasonToEnd.season = MatchmakingTypeSeason(resPost["season"]);
        int mmTypeIndex = g_matchmakingTypes.FindByRef(matchmakingTypeWithSeasonToEnd);
        g_matchmakingTypes.RemoveAt(mmTypeIndex);
        g_matchmakingTypes.InsertAt(mmTypeIndex, matchmakingTypeWithSeasonToEnd);
        Close();
    }

    void RenderDialog() override
    {
        if (!g_connectedPlayer.hasPermission("edit_mmtype")) {
            UI::Text("You don't have permissions !");
            if (UI::Button(Icons::Times + " Close")) Close();
            return;
        }
        UI::Text("Are you sure to end season \"" + matchmakingTypeWithSeasonToEnd.season.name + "\" ?");
        UI::NewLine();
        if (UI::RedButton(Icons::TimesCircle + " End")) {
            startnew(CoroutineFunc(EndSeasonAsync));
            Close();
        }
        UI::SameLine();
        if (UI::Button(Icons::Times + " Cancel")) Close();
    }
}