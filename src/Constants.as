#if CMM_DEV_BUILD
const string PLUGIN_NAME = "Community Matchmaking [DEV]";
#else
const string PLUGIN_NAME = "Community Matchmaking";
#endif
const string PLUGIN_NAME_SHORT = "CMM";
const string COLOR_STR = "\\$63d";
const vec4 COLOR_VEC = Text::ParseHexColor("#6232CE");
const string PLUGIN_ICON = Icons::Globe;
const string ICON_COL = COLOR_STR + PLUGIN_ICON + "\\$z ";

const string URL_PROD = "https://prod.trackmaniacommunitymatchmaking.com";
const string URL_STAGING = "https://staging.trackmaniacommunitymatchmaking.com";
const string URL_LOCALHOST = "http://localhost:3000";