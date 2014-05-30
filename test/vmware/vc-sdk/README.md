vSphere Web Services SDK
------------------------

The VMware vSphere Web Services SDK facilitates development of client applications that target the VMware vSphere API. 
Developers can create client applications to manage, monitor, and maintain VMware vSphere components.

~~~~~~~~~~
Site     : https://www.vmware.com/support/developer/vc-sdk/
Version  : 5.5

Download : https://my.vmware.com/group/vmware/get-download?downloadGroup=WEBSDK550
File     : VMware-vSphere-SDK-5.5.0-1284541.zip
Document : vsdk_prog_guide_5_5.pdf
Document : wssdk_550_dsg.pdf
~~~~~~~~~~


A Case Study of CloneVM
-----------------------

#### Clone VM

`VMware-vSphere-SDK-5.5.0-1284541\SDK\vsphere-ws\java\JAXWS\samples\com\vmware\vm\VMClone.java`

```Java
void cloneVM() {
    // Find the Datacenter reference by using findByInventoryPath().
    ManagedObjectReference datacenterRef =
            vimPort.findByInventoryPath(serviceContent.getSearchIndex(),
                    dataCenterName);
    if (datacenterRef == null) {
        System.out.printf("The specified datacenter [ %s ]is not found %n",
                dataCenterName);
        return;
    }
    // Find the virtual machine folder for this datacenter.
    ManagedObjectReference vmFolderRef =
            (ManagedObjectReference) getDynamicProperty(datacenterRef,
                    "vmFolder");
    if (vmFolderRef == null) {
        System.out.println("The virtual machine is not found");
        return;
    }
    ManagedObjectReference vmRef =
            vimPort.findByInventoryPath(serviceContent.getSearchIndex(),
                    vmPathName);
    if (vmRef == null) {
        System.out.printf("The VMPath specified [ %s ] is not found %n",
                vmPathName);
        return;
    }
    VirtualMachineCloneSpec cloneSpec = new VirtualMachineCloneSpec();
    VirtualMachineRelocateSpec relocSpec = new VirtualMachineRelocateSpec();
    cloneSpec.setLocation(relocSpec);
    cloneSpec.setPowerOn(false);
    cloneSpec.setTemplate(false);

    System.out.printf("Cloning Virtual Machine [%s] to clone name [%s] %n",
            vmPathName.substring(vmPathName.lastIndexOf("/") + 1), cloneName);
    ManagedObjectReference cloneTask =
            vimPort.cloneVMTask(vmRef, vmFolderRef, cloneName, cloneSpec);
    if (getTaskResultAfterDone(cloneTask)) {
        System.out
                .printf(
                        "Successfully cloned Virtual Machine [%s] to clone name [%s] %n",
                        vmPathName.substring(vmPathName.lastIndexOf("/") + 1),
                        cloneName);
    } else {
        System.out.printf(
                "Failure Cloning Virtual Machine [%s] to clone name [%s] %n",
                vmPathName.substring(vmPathName.lastIndexOf("/") + 1),
                cloneName);
    }
}
```

#### Call of vimPort.findByInventoryPath

`VMware-vSphere-SDK-5.5.0-1284541\SDK\vsphere-ws\java\JAXWS\samples\com\vmware\vim25\VimPortType.java`

```Java
/**
 * 
 * @param inventoryPath
 * @param _this
 * @return
 *     returns com.vmware.vim25.ManagedObjectReference
 * @throws RuntimeFaultFaultMsg
 */
@WebMethod(operationName = "FindByInventoryPath", action = "urn:vim25/5.5")
@WebResult(name = "returnval", targetNamespace = "urn:vim25")
@RequestWrapper(localName = "FindByInventoryPath", targetNamespace = "urn:vim25", className = "com.vmware.vim25.FindByInventoryPathRequestType")
@ResponseWrapper(localName = "FindByInventoryPathResponse", targetNamespace = "urn:vim25", className = "com.vmware.vim25.FindByInventoryPathResponse")
public ManagedObjectReference findByInventoryPath(
    @WebParam(name = "_this", targetNamespace = "urn:vim25")
    ManagedObjectReference _this,
    @WebParam(name = "inventoryPath", targetNamespace = "urn:vim25")
    String inventoryPath)
    throws RuntimeFaultFaultMsg
;
```

#### Call of vimPort.cloneVMTask
`VMware-vSphere-SDK-5.5.0-1284541\SDK\vsphere-ws\java\JAXWS\samples\com\vmware\vim25\VimPortType.java`
```Java

@WebMethod(operationName = "CloneVM_Task", action = "urn:vim25/5.5")
@WebResult(name = "returnval", targetNamespace = "urn:vim25")
@RequestWrapper(localName = "CloneVM_Task", targetNamespace = "urn:vim25", className = "com.vmware.vim25.CloneVMRequestType")
@ResponseWrapper(localName = "CloneVM_TaskResponse", targetNamespace = "urn:vim25", className = "com.vmware.vim25.CloneVMTaskResponse")
public ManagedObjectReference cloneVMTask(
    @WebParam(name = "_this", targetNamespace = "urn:vim25")
    ManagedObjectReference _this,
    @WebParam(name = "folder", targetNamespace = "urn:vim25")
    ManagedObjectReference folder,
    @WebParam(name = "name", targetNamespace = "urn:vim25")
    String name,
    @WebParam(name = "spec", targetNamespace = "urn:vim25")
    VirtualMachineCloneSpec spec)
    throws CustomizationFaultFaultMsg, FileFaultFaultMsg, InsufficientResourcesFaultFaultMsg, InvalidDatastoreFaultMsg, InvalidStateFaultMsg, MigrationFaultFaultMsg, RuntimeFaultFaultMsg, TaskInProgressFaultMsg, VmConfigFaultFaultMsg
;
```