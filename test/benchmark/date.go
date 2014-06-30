package main

import (
    "fmt"
    "time"
)

func main() {

    const longForm = "Jan 2, 2006 at 3:04pm (MST)"
    t, _ := time.Parse(longForm, "Feb 3, 2013 at 7:54pm (PST)")
    fmt.Println(t)

    // shortForm is another way the reference time would be represented
    // in the desired layout; it has no time zone present.
    // Note: without explicit zone, returns time in UTC.
    const shortForm = "2006-Feb-02"
    t, _ = time.Parse(shortForm, "2013-Feb-04")
    fmt.Println(t)
}