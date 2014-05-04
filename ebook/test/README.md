About the Date modify in NTFS 
---------------------------------------

At first i try to find the reason why windows explorer (also in Win7) don't display date prior to 1/1/1980.

Only 

I got some interest results when i google the anwser and find a document _NTFS Time Stamps --file created in 1601, modified in 1801 and accessed in 2008!!_ (http://blogs.technet.com/b/ganand/archive/2008/02/19/ntfs-time-stamps-file-created-in-1601-modified-in-1801-and-accessed-in-2008.aspx)

The doc show how to modify ntfs time stamps by using timestomp tools

timestomp
---------

Unfun, I can't find the entried source code now, except some fragments from (https://github.com/rapid7/meterpreter/blob/master/source/extensions/priv/server/timestomp.c). and (http://prp-forensic.googlecode.com/svn/trunk/NTReco/timestomp/timestomp.cpp). 

And done some modifition by using the seconde one, and build it by mingw.

Since I don't got time to complete all missing part. finally I found a binery from (http://www.jonrajewski.com/resources/). 

NSI tool
--------

A tools provide by ms to grab the file sector info in ntfs. (can only show name and location, no details)

http://support.microsoft.com/kb/q253066

```
test.txt
    $STANDARD_INFORMATION (resident)
    $FILE_NAME (resident)
    $DATA (nonresident)
        logical sectors 34575736-34575751 (0x20f9578-0x20f9587)
        logical sectors 35179424-35179439 (0x218cba0-0x218cbaf)
```

$STANDARD_INFORMATION and $FILE_NAME
-----------------------------

Two metadata attributes of interest to investigators in the NTFS file system are the Master File Table (MFT)

$STANDARD_INFORMATION  and $FILE_NAME. Both attributes contain their own entry last modified timestamps. The

MFT $STANDARD_INFORMATION  attribute contains general information about a file such as flags, last accessed,

written, created times, owner, and security ID. The MFT $FILE_NAME attribute contains file name in Unicode,

and also the last accessed, written and created times. 


SetMACE
--------
The _timstomp_ can only modify the MACE in $STANDARD_INFORMATION, but not in $FILE_NAME
So here is another tool SetMACE(http://reboot.pro/files/file/91-setmace/)
and open Source (https://github.com/jschicht/SetMace), although code is in au3 [AutoItScript](http://www.autoitscript.com/site/autoit/)
The _SetMACE_ will modify the MFT directly both for $STANDARD_INFORMATION and $FILE_NAME.


And More
--------

Some other intesting tools no time to try

(http://blog.opensecurityresearch.com/2011/10/how-to-acquire-locked-files-from.html)
