* sample syntax (more firendly to C like like me, Minimalism)
* speed 
* balance dynamic vs. static

Features:

* Multiple results ( func can return any number of results.)
* Named results (resuts can be named and act just like variables)
* var initializers (by this, the variable type can omitted)
* := Short variable declarations. (var keyword can omitted in a function body)
* one 'for' for all
* 'If' with a short statement and variable in 'if' scope
* Slices and re-Slicing (NOTE: new slice points to the same array)
* Range uange ( and skip the index/value by _)
* new vs. make
* closure (A closure is a function value that references variables from outside its body. The function may access and assign to the referenced variables; in this sense the function is "bound" to the variables. )
* a method receiver -> a method under the receiver. (compairing with class's method in java), receiver can be anytype in your package. 
* goroutine , Channels, (buffered channels), range/close, select

NOTES
------

* Why use brace and not white space for indentation

    "We never considered using ..., I just think it's a profound mistake in programming lanaguage design to have your 
    semantic depends on invisible characters. " -- By Rob Pike 
    如出一辙，类似Python这样的语法要求也困扰我好久。

* Why syntax error: unexpected semicolon or newline before { 
    Go does automatic semicolon insertion, and thus the only allowed place for { is at the end of the preceding line
    "semicolon inject rules introducted in Dec 2009,...,directly from BCPL" -- By Rob Pike
    see also : http://golang.org/doc/faq#semicolons

* fmt is format, also by Rob Pike.

* Declare is from left to right, first is _variable_ then _type_

* Go only have 25 keywords now

* Declare
    * Type Declare
    * Variable Declare
    * Function Declare
    * Method Declare 

