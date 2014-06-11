
function test1()
{
    if [ $1 -eq 1 ]; then
        return 0
    else
        return 1
    fi
}

test1 1
echo $?
test1 2
echo $?

function test2()
{
    if [ $1 -eq 1 ]; then
        echo 0
    else
        echo 1
    fi

}

ret=$(test2 1)
echo $ret
echo $?
test2 2
echo $?
test $(test2 1)
echo $?
test $(test2 2)
echo $?

if test1 1; then echo equal ; else echo not-equal ;fi
if test1 2; then echo equal ; else echo not-equal ;fi
if $(test1 1); then echo equal ; else echo not-equal ;fi
if $(test1 2); then echo equal ; else echo not-equal ;fi

echo "test=============2"
if test2 1; then echo equal ; else echo not-equal ;fi
if test2 2; then echo equal ; else echo not-equal ;fi
if [ "$(test2 1)" -eq 0 ]; then echo equal ; else echo not-equal ;fi
if [ "$(test2 2)" -eq 0 ]; then echo equal ; else echo not-equal ;fi


function test3()
{
    if [ $1 -eq 1 ]; then
        echo true
    else
        echo false
    fi

}

if test3 1; then echo equal ; else echo not-equal ;fi
if test3 2; then echo equal ; else echo not-equal ;fi
if $(test3 1); then echo equal ; else echo not-equal ;fi
if $(test3 2); then echo equal ; else echo not-equal ;fi

test $(test3 1) == true
echo $?
test $(test3 2) == false
echo $?
test $(test3 2) == "false"
echo $?
test $(test3 2) == "other"
echo $?

function test4()
{
    if [ $1 -eq 1 ]; then
        return 0
    else
        return 1
    fi
}

if test4 1; then echo "1=1" ; else echo "1<>1"; fi;
if test4 2; then echo "1=2" ; else echo "1<>2"; fi;

function test5()

