namespace API
{
    Net::HttpRequest@ Get(const string &in url)
    {
        auto ret = Net::HttpRequest();
        ret.Method = Net::HttpMethod::Get;
        ret.Url = url;
        if (url.StartsWith(Setting_BaseURL) && Auth::connected && Auth::AccountToken.Length > 0) {
            ret.Headers.Set("Authorization", "Bearer " + Auth::AccountToken);
        }
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

    Net::HttpRequest@ Post(const string &in url, const string &in body = "")
    {
        auto ret = Net::HttpRequest();
        ret.Method = Net::HttpMethod::Post;
        ret.Url = url;
        ret.Body = body;
        ret.Headers.Set("Content-Type", "application/json");
        if (url.StartsWith(Setting_BaseURL) && Auth::connected && Auth::AccountToken.Length > 0) {
            ret.Headers.Set("Authorization", "Bearer " + Auth::AccountToken);
        }
        if (Meta::IsDeveloperMode()) Log::Trace("Post: " + url);
        if (Meta::IsDeveloperMode()) Log::Trace("Body: " + body);
        ret.Start();
        return ret;
    }

    Json::Value PostAsync(const string &in url, const string &in body = "")
    {
        auto req = Post(url, body);
        while (!req.Finished()) {
            yield();
        }
        string resStr = req.String();
        if (Meta::IsDeveloperMode()) Log::Trace("PostAsync Res: " + resStr);
        return Json::Parse(resStr);
    }

    Net::HttpRequest@ Put(const string &in url, const string &in body = "")
    {
        auto ret = Net::HttpRequest();
        ret.Method = Net::HttpMethod::Put;
        ret.Url = url;
        ret.Body = body;
        ret.Headers.Set("Content-Type", "application/json");
        if (url.StartsWith(Setting_BaseURL) && Auth::connected && Auth::AccountToken.Length > 0) {
            ret.Headers.Set("Authorization", "Bearer " + Auth::AccountToken);
        }
        if (Meta::IsDeveloperMode()) Log::Trace("Put: " + url);
        if (Meta::IsDeveloperMode()) Log::Trace("Body: " + body);
        ret.Start();
        return ret;
    }

    Json::Value PutAsync(const string &in url, const string &in body = "")
    {
        auto req = Put(url, body);
        while (!req.Finished()) {
            yield();
        }
        string resStr = req.String();
        if (Meta::IsDeveloperMode()) Log::Trace("PutAsync Res: " + resStr);
        return Json::Parse(resStr);
    }

    Net::HttpRequest@ Delete(const string &in url)
    {
        auto ret = Net::HttpRequest();
        ret.Method = Net::HttpMethod::Delete;
        ret.Url = url;
        if (url.StartsWith(Setting_BaseURL) && Auth::connected && Auth::AccountToken.Length > 0) {
            ret.Headers.Set("Authorization", "Bearer " + Auth::AccountToken);
        }
        if (Meta::IsDeveloperMode()) Log::Trace("Delete: " + url);
        ret.Start();
        return ret;
    }

    Json::Value DeleteAsync(const string &in url)
    {
        auto req = Delete(url);
        while (!req.Finished()) {
            yield();
        }
        string resStr = req.String();
        if (Meta::IsDeveloperMode()) Log::Trace("DeleteAsync Res: " + resStr);
        return Json::Parse(resStr);
    }
}