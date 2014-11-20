echo "------------------------------"
echo "Benchmark for bash"
echo "------------------------------"
time ./listvm.sh
echo
echo "------------------------------"
echo "Benchmark for go script"
echo "------------------------------"
time go run listvm-go.go
echo
echo "------------------------------"
echo "Benchmark for go native"
echo "------------------------------"

if [ ! -f listvm-go.exe ]; then
	go build listvm-go.go
fi
time listvm-go.exe