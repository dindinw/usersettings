var echo = console.log;
var ISBN10_REGXP="\\d{9}[\\d|X]"
var ISBN13_REGXP="(978|979)(?:-|)\\d{9}[\\d|X]"


var isbn13 = new RegExp('^'+ISBN13_REGXP)
var isbn10 = new RegExp('^'+ISBN10_REGXP)

echo("13",isbn13.test("978-0321942050"));
echo("13",isbn13.test("9780321942050"));
echo("13",isbn13.test("978-6"));
echo("10",isbn10.test("0321942051"));
echo("13",isbn13.test("0321942051"));
echo("10",isbn10.test("978-0321942050"));
echo("13",isbn13.test("978-0321942050"));