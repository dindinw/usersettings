The folder to save vijava lib, download _vijava55b20130927.zip_ and extract jars to the folder

VMware Infrastructure (vSphere) Java API
----------------------------------------

A open source vmware java client API

### Why is better than VMware SDK API?
  * Reduces the need to use `ManagedObjectReference` and makes possible 
    compile time type checking
  * Hides the complexity of the `PropertyCollector`
  * Provides necessary utility classes to simplify VI SDK web interfaces
  * High performance with 4+ times faster than AXIS engine

```
Offical page : http://sourceforge.net/projects/vijava/
Version : vijava55b20130927
Down    : http://sourceforge.net/projects/vijava/files/vijava/VI%20Java%20API%205.5%20Beta/vijava55b20130927.zip/download
```

More Details here (http://www.doublecloud.org/2013/09/announcing-vi-java-api-5-5-beta-supporting-vsphere-5-5/)


A Case Study for CloneVM
------------------------

#### CloneVM

(http://sourceforge.net/p/vijava/code/HEAD/tree/trunk/src/com/vmware/vim25/mo/samples/vm/CloneVM.java)

```Java
package com.vmware.vim25.mo.samples.vm;

import java.net.URL;

import com.vmware.vim25.VirtualMachineCloneSpec;
import com.vmware.vim25.VirtualMachineRelocateSpec;
import com.vmware.vim25.mo.Folder;
import com.vmware.vim25.mo.InventoryNavigator;
import com.vmware.vim25.mo.ServiceInstance;
import com.vmware.vim25.mo.Task;
import com.vmware.vim25.mo.VirtualMachine;

public class CloneVM 
{
  public static void main(String[] args) throws Exception
  {
    if(args.length!=5)
    {
      System.out.println("Usage: java CloneVM <url> " +
      "<username> <password> <vmname> <clonename>");
      System.exit(0);
    }

    String vmname = args[3];
    String cloneName = args[4];

    ServiceInstance si = new ServiceInstance(
        new URL(args[0]), args[1], args[2], true);

    Folder rootFolder = si.getRootFolder();
    VirtualMachine vm = (VirtualMachine) new InventoryNavigator(
        rootFolder).searchManagedEntity(
            "VirtualMachine", vmname);

    if(vm==null)
    {
      System.out.println("No VM " + vmname + " found");
      si.getServerConnection().logout();
      return;
    }

    VirtualMachineCloneSpec cloneSpec = 
      new VirtualMachineCloneSpec();
    cloneSpec.setLocation(new VirtualMachineRelocateSpec());
    cloneSpec.setPowerOn(false);
    cloneSpec.setTemplate(false);

    Task task = vm.cloneVM_Task((Folder) vm.getParent(), 
        cloneName, cloneSpec);
    System.out.println("Launching the VM clone task. " +
        "Please wait ...");

    String status = task.waitForMe();
    if(status==Task.SUCCESS)
    {
      System.out.println("VM got cloned successfully.");
    }
    else
    {
      System.out.println("Failure -: VM cannot be cloned");
    }
  }
}
```

#### InventoryNavigator.searchManagedEntity

(http://sourceforge.net/p/vijava/code/HEAD/tree/trunk/src/com/vmware/vim25/mo/InventoryNavigator.java)

```Java
    return pc.retrieveProperties(new PropertyFilterSpec[] { spec } );
```

##### PropertyCollector->VimStub.retrieveProperties

```Java
public ObjectContent[] retrieveProperties(ManagedObjectReference _this, PropertyFilterSpec[] specSet) throws java.rmi.RemoteException, InvalidProperty, RuntimeFault {
  Argument[] paras = new Argument[2];
  paras[0] = new Argument("_this", "ManagedObjectReference", _this);
  paras[1] = new Argument("specSet", "PropertyFilterSpec[]", specSet);
  return (ObjectContent[]) wsc.invoke("RetrieveProperties", paras, "ObjectContent[]");
}
```

#### VirtualMachine.cloneVM_Task

http://sourceforge.net/p/vijava/code/HEAD/tree/trunk/src/com/vmware/vim25/mo/VirtualMachine.java

```Java
public Task cloneVM_Task(Folder folder, String name, VirtualMachineCloneSpec spec) throws VmConfigFault, TaskInProgress, CustomizationFault, FileFault, InvalidState, InsufficientResourcesFault, MigrationFault, InvalidDatastore, RuntimeFault, RemoteException 
{
  if(folder==null)
  {
    throw new IllegalArgumentException("folder must not be null.");
  }
  ManagedObjectReference mor = getVimService().cloneVM_Task(getMOR(), folder.getMOR(), name, spec);
  return new Task(getServerConnection(), mor);
}
```


#### VimSerice->VimPortType->VimStub.cloneVM_Task

(http://sourceforge.net/p/vijava/code/HEAD/tree/trunk/src/com/vmware/vim25/ws/VimStub.java)

```Java
public ManagedObjectReference cloneVM_Task(ManagedObjectReference _this, ManagedObjectReference folder, String name, VirtualMachineCloneSpec spec) throws java.rmi.RemoteException, CustomizationFault, InvalidState, InvalidDatastore, TaskInProgress, VmConfigFault, FileFault, MigrationFault, InsufficientResourcesFault, RuntimeFault {
  Argument[] paras = new Argument[4];
  paras[0] = new Argument("_this", "ManagedObjectReference", _this);
  paras[1] = new Argument("folder", "ManagedObjectReference", folder);
  paras[2] = new Argument("name", "String", name);
  paras[3] = new Argument("spec", "VirtualMachineCloneSpec", spec);
  return (ManagedObjectReference) wsc.invoke("CloneVM_Task", paras, "ManagedObjectReference");
}
```

#### WSClient.invoke

(http://sourceforge.net/p/vijava/code/HEAD/tree/trunk/src/com/vmware/vim25/ws/WSClient.java)

```Java
public Object invoke(String methodName, Argument[] paras, String returnType) throws RemoteException
{
  String soapMsg = XmlGen.toXML(methodName, paras, this.vimNameSpace);
  
  InputStream is = null;
  try 
  {
    is = post(soapMsg);
    return xmlGen.fromXML(returnType, is);
  }
  catch (Exception e1) 
  {
    throw new RemoteException("VI SDK invoke exception:" + e1);
  }
  finally
  {
    if(is!=null) 
      try { is.close(); } catch(IOException ioe) {}
  }
}

```


