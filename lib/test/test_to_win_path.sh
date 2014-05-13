#!/bin/bash
source ../core.sh

echo "-------------------------------------------------------------------------"
echo 'to_win_path():'
echo "/c/test/test ->" $(to_win_path "/c/test/test")
echo "test/test" "->" $(to_win_path "test/test")
echo "\"\"" "->" $(to_win_path "")
echo "" "->" $(to_win_path)
echo "/" "->" $(to_win_path "/")
echo "./test" "->" $(to_win_path "./test")
echo '$HOME' "->" $(to_win_path $HOME)
echo '$HOME/Downloads' "->" $(to_win_path "$HOME/Downloads")
echo '"$HOME/no_exist/not/not' "->" $(to_win_path "$HOME/no_exist/not/not") 
echo "-------------------------------------------------------------------------"
echo 'to_win_path2():'
echo "/c/test/test ->" $(to_win_path2 "/c/test/test")
echo "test/test" "->" $(to_win_path2 "test/test")
echo "\"\"" "->" $(to_win_path2 "")
echo "" "->" $(to_win_path2)
echo "/" "->" $(to_win_path2 "/")
echo "./test" "->" $(to_win_path2 "./test")
echo '$HOME' "->" $(to_win_path2 $HOME)
echo '$HOME/Downloads' "->" $(to_win_path2 "$HOME/Downloads")
echo '"$HOME/no_exist/not/not' "->" $(to_win_path2 "$HOME/no_exist/not/not") 