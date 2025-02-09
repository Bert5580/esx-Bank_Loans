local CurrentVersion = "Ev0.0.0" -- Current ESX version
local RepoURL = "https://api.github.com/repos/Bert5580/esx-Bank_Loans/releases/latest"

-- Function: Check for updates from GitHub
local function CheckForUpdates()
    PerformHttpRequest(RepoURL, function(statusCode, response)
        if statusCode == 200 and response then
            local LatestVersion = response:match('"tag_name":"(.-)"')
            if LatestVersion and LatestVersion ~= CurrentVersion then
                print(string.format(
                    "[Bank Loans]: \27[33mA new version is available! (Current: %s, Latest: %s)\27[0m",
                    CurrentVersion, LatestVersion
                ))
                print(string.format(
                    "[Bank Loans]: Download it at: \27[31mhttps://github.com/Bert5580/Esx-Bank_Loans/releases/tag/%s\27[0m",
                    LatestVersion
                ))
            else
                print("[Bank Loans]: You are using the latest version.")
            end
        else
            print("[Bank Loans]: Failed to check for updates. HTTP Error:", statusCode)
        end
    end, "GET", "", { ["User-Agent"] = "Mozilla/5.0" })
end
