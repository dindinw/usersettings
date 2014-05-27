# Gloovy
# ------
# 1. install gloovy from http://groovy.codehaus.org/Download
# for example, http://dist.codehaus.org/groovy/distributions/installers/windows/nsis/groovy-2.3.1-installer.exe
# 2. mark sure the %GROOVY_HOME% in enviorment var.


# Using java -cp to execute the complied groovy script
_FUNC_VMWARE_CLEAN=1

function _clean_file(){
    local file="$1"
    if [[ $_FUNC_VMWARE_CLEAN -eq 1 ]]; then
        if [[ -f $file ]]; then
            #echo clean $file
            rm $file
        fi
    fi
}

function run_compiled_groovy(){
    local g_script="$1"
    pushd "$GROOVY_HOME" >/dev/null
    GROOVY_JAR=$(ls embeddable/groovy-all-*[0-9].jar)
    popd >/dev/null
    if [[ -z "$GROOVY_JAR" ]]; then
        echo '$GROOVY_JAR not found, check $GROOVY_HOME enviorment varible'
    fi
    echo "compile $g_script ..."
    groovyc -d classes $g_script
    echo "execute by java"
    java -cp "$(to_win_path "$GROOVY_HOME/$GROOVY_JAR");classes" $(basename $g_script .groovy)
    rm -rf classes
}
#run_compiled_groovy hello_vijava.groovy

# exectue groovy script with vijava lib
# vijava
# ------
# look at the sample code from http://sourceforge.net/p/vijava/code/HEAD/tree/trunk/src/com/vmware/vim25/mo/samples/

function run_groovy_with_vijavalib(){
    local g_script="$1"
    local VIJAVALIB="./vijava/dom4j-1.6.1.jar;./vijava/vijava55b20130927.jar;./vijava"
    groovy -cp "$VIJAVALIB" $g_script
    _clean_file $g_script
}


function vijava_listvm() {

cat <<EOF > _vijava_listvm.groovy
/*
 * from http://sourceforge.net/p/vijava/code/HEAD/tree/trunk/src/com/vmware/vim25/mo/samples/HelloVM.java
 */
    import java.net.URL
    import com.vmware.vim25.*
    import com.vmware.vim25.mo.*
    println 'hello groovy with vijava, try to use groovy script to simplfy the vmware sdk'
    def start = System.currentTimeMillis()
    def si = new ServiceInstance(new URL("https://${VCENTER_IP}/sdk"), "${VCENTER_USER}","${VCENTER_PASS}", true)
    def end = System.currentTimeMillis()
    println "time taken: " + (end-start)
    def rootFolder = si.getRootFolder()
    def name = rootFolder.getName()
    println "root: " + name
    def mes = new InventoryNavigator(rootFolder).searchManagedEntities("VirtualMachine")
    mes.each {
        println ""
        println "VM Name            : " + it.getName()
        println "GustOS             : " + it.getConfig().getGuestFullName()
        println "Multiple snapshots : " + it.getCapability().isMultipleSnapshotsSupported()
    }
    si.getServerConnection().logout()
EOF

run_groovy_with_vijavalib _vijava_listvm.groovy

}

function ovftool_import() {

    local LOGFILE="ovftool-log.txt"
    local DISK_MODE="thin"
    
    local ovf_source="$1"
    local vcenter_path="$2"
    local vcenter_loc="vi://${VCENTER_USER}:${VCENTER_PASS}@${VCENTER_IP}/${vcenter_path}"
    local vcenter_data_storage="$3"
    local vcenter_network="$4"
    local vm_name="$5"
    local vm_folder="$6"

    ovftool --X:logFile=${LOGFILE} --X:logLevel=verbose \
      --compress=9 \
      --noSSLVerify \
      --name=${vm_name} \
      --vmFolder=${vm_folder} \
      --datastore=${vcenter_data_storage} \
      --diskMode=${DISK_MODE} \
      --network="${vcenter_network}" \
      $ovf_source $vcenter_loc
      

    _clean_file $LOGFILE
}

function ovftool_help(){
    ovftool -h 
}

function ovftool_find_path() {
    ovftool vi://${VCENTER_USER}":"${VCENTER_PASS}@${VCENTER_IP}
}
