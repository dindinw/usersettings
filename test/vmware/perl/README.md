vSphere SDK for Perl
---------------------

The VMMare offical Perl SDK. Which is a client-side Perl framework that provides an easy-to-use scripting interface to the vSphere Web Services API.

~~~~~~~~~~
Site     : https://www.vmware.com/support/developer/viperltoolkit/
Version  : 5.5
Download : https://my.vmware.com/web/vmware/details?productId=353&downloadGroup=SDKPERL550
~~~~~~~~~~


Some Internal Note
-------------------

* The Perl script will call Web Service (by SOAP) to access(modify) server-side objects to client-side stub to act as a reference of service side object. aka the _ManagedObjectReference_.

* You can use the MOB (Managed Object Browser) to explore the server-side objects by url https://<vcenter_ip>/mob


A Case Study of CloneVM Task
-----------------------------

### The Uage of vmclone.pl 

**vmclone.pl** is under `C:\Program Files (x86)\VMware\VMware vSphere CLI\Perl\apps\vm\vmclone.pl`

The command usage for making a clone without any customization:
~~~~~~~~~~~
perl vmclone.pl --username username --password mypassword
                 --vmhost <hostname/ipaddress> --vmname DVM1 --vmname_destination DVM99
                 --url https://<ipaddress>:<port>/sdk/webService
~~~~~~~~~~~~

THe the case we will clone a VM named '071113_min_rhel6u4_FoundationServices1.5.03' to 'FoundationServices_Clone'

~~~~~~~~~~~
perl vmclone.pl --url https://<venter_ip>/sdk/webService --username user --password password --vmname 071113_min_rhel6u4_FoundationServices1.5.03 --vmhost 10.20.22.241 --vmname_destination FoundationServices_Clone
~~~~~~~~~~~

### Call detail in vmclone.pl

#### 1. Get View by vmname

in the case `071113_min_rhel6u4_FoundationServices1.5.03` aka check if the vm exist.

~~~~~~~~~~~
my $vm_name = Opts::get_option('vmname');
my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine',
                                     filter => {'name' =>$vm_name});
~~~~~~~~~~~

#### 2. Get the hostView by vmhost

in the case `10.20.22.241`, aka, check if the host exist.

~~~~~~~~~~~
my $host_name =  Opts::get_option('vmhost');
my $host_view = Vim::find_entity_view(view_type => 'HostSystem',
                                filter => {'name' => $host_name});
~~~~~~~~~~~

#### 3. Build VirtualMachineRelocateSpec

try to relocate resource : datastore. host, resourcepool.  

~~~~~~~~~~~
my $relocate_spec =
VirtualMachineRelocateSpec->new(datastore => $ds_info{mor},
                              host => $host_view,
                              pool => $comp_res_view->resourcePool);
~~~~~~~~~~~

#### 4. Build VirtualMachineCloneSpec

~~~~~~~~~~~
$clone_spec = VirtualMachineCloneSpec->new(
                                powerOn => 0,
                                template => 0,
                                location => $relocate_spec,
                                );
~~~~~~~~~~~

#### 5. Do CloneVM 

~~~~~~~~~~~
$_->CloneVM(folder => $_->parent,
               name => Opts::get_option('vmname_destination'),
               spec => $clone_spec);
~~~~~~~~~~~

### Internal Calling of CloneVM

~~~~~~~~~~~
....
package VirtualMachineOperations;
sub CloneVM_Task {
   my ($self, %args) = @_;
   my $response = Util::check_fault($self->invoke('CloneVM_Task', %args));
   return $response
}

sub CloneVM {
   my ($self, %args) = @_;
   return $self->waitForTask($self->CloneVM_Task(%args));
}
....

package VimService;
....
sub CloneVM_Task {
   my ($self, %args) = @_;
   my $vim_soap = $self->{vim_soap};
   my @arg_list = (['_this', 'ManagedObjectReference'],['folder', 'ManagedObjectReference'],['name', undef],['spec', 'VirtualMachineCloneSpec'],);
   my $arg_string = build_arg_string(\@arg_list, \%args);
   my $soap_action = '"urn:vim25/test"';
   my ($result, $fault) = $vim_soap->request('CloneVM_Task', $arg_string, $soap_action);
   return deserialize_response($result, $fault, 'ManagedObjectReference', 0);
}
....
~~~~~~~~~~~

### The HTTP (SOAP) Request Internal Details

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<soapenv:Body>
<CloneVM_Task xmlns="urn:vim25">
    <_this type="VirtualMachine">vm-66166</_this>
    <folder type="Folder">group-v22416</folder>
    <name>FoundationServices_Clone</name>
    <spec>
        <location>
            <datastore type="Datastore">datastore-62</datastore>
            <pool type="ResourcePool">resgroup-20</pool>
            <host xsi:type="ManagedObjectReference" type="HostSystem">host-60775</host>
        </location>
        <template>0</template>
        <powerOn>0</powerOn>
    </spec>
</CloneVM_Task>
</soapenv:Body>
</soapenv:Envelope>

SOAPAction -> "urn:vim25/test"
HTTP -> POST
length -> 737
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
