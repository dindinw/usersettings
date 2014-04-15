### Chrome

Release site : (http://googlechromereleases.blogspot.com/)

#### Windows

* Install Files (_from google, only MSI version works with install scripts below_)
    - [Standalone Download][chrome_win]
    - [MSI Downlaod][chrome_win_msi]

* Install Scripts (_save the files in the same folder, tesed on XP only_)
    - [install_chrome.bat] [my_chrome_script_1] 
    - [remove_chrome.bat] [my_chrome_script_2]
    - [master_preferences][my_chrome_perf]

[chrome_win]:https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7B4CCCCB56-E8B8-F482-D457-3DF54C9B95C0%7D%26lang%3Den%26browser%3D3%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dtrue%26installdataindex%3Ddefaultbrowser/update2/installers/ChromeStandaloneSetup.exe
[chrome_win_msi]:https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7BCA8DF948-A4C1-39A2-F252-9F2344D3C552%7D%26lang%3Den%26browser%3D4%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers/edgedl/chrome/install/GoogleChromeStandaloneEnterprise.msi
[my_chrome_script_1]:https://github.com/dindinw/usersettings/raw/master/chrome/install_chrome.bat
[my_chrome_script_2]:https://github.com/dindinw/usersettings/raw/master/chrome/remove_chrome.bat
[my_chrome_perf]:https://github.com/dindinw/usersettings/raw/master/chrome/master_preferences

The [documentation][chrome_master_perf_doc] for master_preferences. and an [example][chrome_master_perf_example].

Home Page Location  : (http://www.chromium.org/administrators/policy-list-3#Homepage)
    
* ~~Software\Policies\Google\Chrome\HomepageLocation~~
* ~~HKEY_CURRENT_USER\Software\Policies\Google\Chrome\HomepageLocation~~ 

(_simply create reg key will not work since 28, need to use group policy_)

Policy Template : (http://dl.google.com/dl/edgedl/chrome/policy/policy_templates.zip)
  
#### Linux
_TODO_
#### Mac
_TODO_


[chrome_master_perf_doc]:https://support.google.com/chrome/a/answer/187948
[chrome_master_perf_example]:http://www.chromium.org/administrators/configuring-other-preferences#TOC-Preferences-List