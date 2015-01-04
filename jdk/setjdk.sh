# The java_home tool 
# /usr/libexec/java_home -> /System/Library/Frameworks/JavaVM.framework/Versions/Current/Commands/java_home/
# The script is an modified verison orignal from http://www.jayway.com/2014/01/15/how-to-switch-jdk-version-on-mac-os-x-maverick/

java_home_exec=/usr/libexec/java_home
if [ ! -e $java_home_exec ]; then
   echo "ERROR: $java_home_exec not exist"
fi
function list_jdk()
{
  allJdkVersions=$($java_home_exec -V)
}
function switch_jdk()
{
  JAVA_HOME=`$java_home_exec -v $@`
  if [ $? -eq 0 ]; then
    # get java_home ok
    export JAVA_HOME=$JAVA_HOME
    echo "Set JDK VERSION to $@"
    echo "JAVA_HOME=$JAVA_HOME"
    java -version
  else
    echo "Unsupport Version" $@ 
  fi
}
function set_jdk() 
{
 if [ $# -ne 0 ]; then
   switch_jdk $@
 else
   echo "all availiable jdk :"
   list_jdk
   echo "Please enter jdk version "
   read jdkVersionInput
   if [ ! -z $jdkVersionInput ]; then
     switch_jdk $jdkVersionInput
   fi
 fi
}
