 The instructions of how to set up developer environment under various platform and a collection of useful developer environment setting script and files.

Basic Build Env
===============

Linux
-----
### Gcc/make

    sudo apt-get install build-essential 

Mac
---

### Xcode
### Homebrew

Win
---

### Cgwin
### VC Express

Java
====

Linux
-----
### JDK
 

#### OpenJDK 
    sudo apt-get install openjdk-7-jdk openjdk-7-source
    sudo update-java-alternatives -s java-1.7.0-openjdk-i386    
#### Oracle JDK
* NOTE: JDK 8 released on 18 March 2013.
    wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8-b132/jdk-8-linux-i586.tar.gz"
    tar xzvf jdk-8-linux-i586.tar.gz 
    sudo mv ./

* Maven

Javascript
==========

* NodeJs

Editors
=======

* VIM
* Sublime


IDE
===

Eclipse
-------

The very useful plugin [workspace mechanic][1]

[1]:https://code.google.com/a/eclipselabs.org/p/workspacemechanic/
