# A "proper" Makefile for compiling with MinGW under msys.
cc		=	gcc
ln		=	ln
EXE		=	.exe
TARGETS	=	nc$(EXE)
lflags 	=	-lkernel32,-luser32,-lwinmm,-lws2_32
cflags	=	-c -DGAPING_SECURITY_HOLE
lib		=	/lib

all: nc.exe

getopt.o: getopt.c
	$(cc) $(cflags) getopt.c

doexec.o: doexec.c
	$(cc) $(cflags) doexec.c

netcat.o: netcat.c
	$(cc) $(cflags) netcat.c


linkit: getopt.o doexec.o netcat.o
	$(ln) getopt.o doexec.o netcat.o

clean:
	rm -f *.o;

cleanall:
	rm -f *.o;
	rm -f $(TARGETS);
	
# Apperntly lflags must be at the end or linking fails...	
nc.exe: getopt.o doexec.o netcat.o
	$(cc) getopt.o doexec.o netcat.o --output $(TARGETS) -Wl,-L"$(lib)",$(lflags)
