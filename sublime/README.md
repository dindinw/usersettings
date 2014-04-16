sublime
-------

Offical home page : http://www.sublimetext.com/
   
   * Version 2 [Download][v2_down]
   * Version 3 Beta [Download][v3_down]

[v2_down]:http://www.sublimetext.com/2
[v3_down]:http://www.sublimetext.com/3

### Note for XP 

** Unicode Error **
`UnicodeDecodeError: 'ascii' codec can't decode byte 0xe6 in position 15: ordinal not in range(128)`

need to change a line in _Sublime Text 2\Packages\Default\exec.py_

```Python
for k, v in proc_env.iteritems():
            proc_env[k] = os.path.expandvars(v).encode(sys.getfilesystemencoding())
# change the line to 
proc_env[k] = os.path.expandvars(v.decode(sys.getfilesystemencoding())).encode(sys.getfilesystemencoding())
```
More details : see [1][ref1] and [2][ref2]

[ref1]:https://github.com/misfo/Shell-Turtlestein/issues/6#issuecomment-4249064
[ref2]:http://www.sublimetext.com/forum/viewtopic.php?f=3&t=2441&start=0&hilit=getfilesystemencoding

### Setup Sublime Text 

#### User Setting

`Ctrl-P`-> `user`

The 4 space per tab 

```
{
    "tab_size": 4,
    "translate_tabs_to_spaces": true, 
    "detect_indentation": false
}
```
 note: `detect_indentation` to `false` will let Sublime stop to guess which indendation style to use when opening files.
 
#### Active Vim mode

1. for sublime 2, [vintage][v1] is good enough.

presss command-P Prefersu, add fellowing settings

```
{
    //enable "Vintage"
    "ignored_packages": []
}
```
2. for sublime 3 , use [vintagous][v2] instead.
Download from [here][v2_d], copy into "/Users/{your_name}/Library/Application Support/Sublime Text 3/Installed Packages/" folder
BTW, although the office doc says vintagous need to ensure Vintage is in the ignored_packages, wried the two can work together in my test.

3. In Mac, need to disable repeat key context menu, see [here][key_repeat] for more details

```
defaults write com.sublimetext.3 ApplePressAndHoldEnabled -bool false
```

[v1]:http://www.sublimetext.com/docs/2/vintage.html
[v2]:https://github.com/guillermooo/Vintageous
[v2_d]:https://bitbucket.org/guillermooo/vintageous/downloads/Vintageous.sublime-package
[key_repeat]:https://gist.github.com/kconragan/2510186

#### Install Package Installer

Download from [wbond site][pkgctr]

[pkgctr]:https://sublime.wbond.net/installation

#### Install Md extend syntax highlight

- Install : `CMD-P` -> enter `pkgin` -> enter `markdownextend`

- Make it default : `View -> Syntax -> Open all with current extension as... -> Markdown Extended`

#### Install Md preview 

- Install : `CMD-P` -> enter `pkgin` -> enter `markdownpreview`
- Usage : `Ctrl-P` (Windows/Linux) or `CMD-P` (Mac) -> enter `prewb`

#### Console 

``Ctrl-` `` will open a python console (with embeded inside sublime).

#### Terminal

Sometimes, you may want a os terminal inside your working folder, here a plugin called [sublime_terminal][s_t] is.

- Install : `Ctrl-P` -> `pkgin` -> `terminal`
- Usage : 
    - `Ctrl-T` open under your file
    - `Ctrl-Alt-T` open under your project 

[s_t]: https://github.com/wbond/sublime_terminal


#### Git plugin

- Install : `Ctrl-P` -> 'pkgin' -> `git` 
- Usage : 
    - `Ctrl-P` -> `gits` : list git status 

Very useful, see the [wiki][sublime-git] for more details.

[sublime-git]:https://github.com/kemayo/sublime-text-git/wiki

#### Advanced New File

A plugin to create file folder also 
See [here][sublime-anf] for details

- Install : `Ctrl-P` -> 'pkgin' -> 'AdvancedNewFile' 
- Usage : `Ctrl-alt-N` 

[sublime-anf]: https://github.com/skuroda/Sublime-AdvancedNewFile

#### Nettuts+ Fetch

fetch a file/files from remote (look it as a curl command executed by a inputted key).

see [usage][net-fetch-usage]

[net-fetch]:https://github.com/weslly/Nettuts-Fetch
[net-fetch-usage]:http://code.tutsplus.com/articles/introducing-nettuts-fetch--net-23490

#### Sublime Prefixr
runs CSS through the Prefixr API (create cross-browser css)

[prefixr]:https://github.com/wbond/sublime_prefixr

#### Shell Turtlestein

- Uasge : `Ctrl-Shift-C`  (Quit use ESC, up and down see the history commands)

[shell-t]:https://github.com/misfo/Shell-Turtlestein
[shell-t-d]:https://sublime.wbond.net/packages/Shell%20Turtlestein

#### Sidebar Enhancements

[sidebar]:https://github.com/titoBouzout/SideBarEnhancements

#### SublimeREPL

- Install : `CMD-P` -> `pkgin` -> 'sublimerepl' (need to restart )

repl:shell can open a os shell  

[repl]: https://github.com/wuub/SublimeREPL/

#### sublime-github

[sub-github]:https://github.com/bgreenlee/sublime-github

#### Jshint

[jshint]: https://github.com/uipoet/sublime-jshint

#### sublime linter
A framework for interactive code linting

[sublimelinter]:https://github.com/SublimeLinter/SublimeLinter3
[linter_intro]:http://sublimelinter.readthedocs.org/en/latest/about.html#what-is-a-linter

html-tidy

[sublimelinter_html]:https://github.com/SublimeLinter/SublimeLinter-html-tidy

#### SublimeCodeIntel

Better than the default code complete.

[sub-codeintel]:https://github.com/SublimeCodeIntel/SublimeCodeIntel


#### Tag

[tag]: https://github.com/SublimeText/Tag

#### Build JavaScript code

Go to "Tools > Build System > New Build System" , add code like:

```
{
    "cmd": ["node","$file"],
    "selector": "source.js"
}
```

After that, we can use `ctrl-B` to build JavaScript.

#### Node.js binding

[node-snippets]:https://github.com/zenorocha/sublime-snippets-js/

[sublimetext-nodejs]:https://github.com/tanepiper/SublimeText-Nodejs


