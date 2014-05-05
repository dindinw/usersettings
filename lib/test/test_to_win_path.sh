#!/bin/bash
source ../core.sh

to_win_path "test/test"
to_win_path ""
to_win_path
to_win_path "/"
to_win_path "./test"
to_win_path $HOME
to_win_path "$HOME/Downloads"
to_win_path "$HOME/no_exist/not/not"

to_win_path2 "test/test"
to_win_path2 ""
to_win_path2
to_win_path2 "/"
to_win_path2 "./test"
to_win_path2 $HOME
to_win_path2 "$HOME/Downloads"
to_win_path2 "$HOME/no_exist/not/not"