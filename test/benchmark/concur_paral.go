package main

import (
    "fmt"
    "runtime"
)

func say(s string) {
    for i := 0; i < 5; i++ {
        runtime.Gosched()
        fmt.Println(s)
    }
}

func main() {
    runtime.GOMAXPROCS(8) 
    go say("world") //开一个新的Goroutines执行
    say("hello") //当前Goroutines执行
}

// without runtime.GOMAXPROCS, 输出是固定的。
// go run '.\concur&paral.go'
// hello
// world
// hello
// world
// hello
// world
// hello
// world
// hello

//
// GOMAXPROCS 设置了同时运行逻辑代码的系统线程的最大数量, add runtime.GOMAXPROCS(8) 
// go run '.\concur&paral.go'
// hello
// hello
// world
// hello
// world
// hello
// world
// hello
// go run '.\concur&paral.go'
// hello
// world
// hello
// world
// hello
// world
// hello
// world
// hello
// go run '.\concur&paral.go'
// world
// hello
// world
// hello
// world
// hello
// world
// hello
// world
// hello
