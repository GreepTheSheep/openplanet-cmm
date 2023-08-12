namespace API
{
    Net::HttpRequest@ Get(const string &in url)
    {
        auto ret = Net::HttpRequest();
        ret.Method = Net::HttpMethod::Get;
        ret.Url = url;
        if (Meta::IsDeveloperMode()) Log::Trace("Get: " + url);
        ret.Start();
        return ret;
    }

    Json::Value GetAsync(const string &in url)
    {
        auto req = Get(url);
        while (!req.Finished()) {
            yield();
        }
        string resStr = req.String();
        if (Meta::IsDeveloperMode()) Log::Trace("GetAsync Res: " + resStr);
        return Json::Parse(resStr);
    }

    Net::HttpRequest@ Post(const string &in url, const string &in body)
    {
        auto ret = Net::HttpRequest();
        ret.Method = Net::HttpMethod::Post;
        ret.Url = url;
        ret.Body = body;
        ret.Headers.Set("Content-Type", "application/json");
        if (Meta::IsDeveloperMode()) Log::Trace("Post: " + url);
        if (Meta::IsDeveloperMode()) Log::Trace("Body: " + body);
        ret.Start();
        return ret;
    }

    Json::Value PostAsync(const string &in url, const string &in body)
    {
        auto req = Post(url, body);
        while (!req.Finished()) {
            yield();
        }
        string resStr = req.String();
        if (Meta::IsDeveloperMode()) Log::Trace("PostAsync Res: " + resStr);
        return Json::Parse(resStr);
    }
}