. ./_test_create_vm_common.sh
. ./create_vm.sh

# The ks.cfg file of centos can work with redhat directly.
#
function start_tftp_win(){
    # overwrriten the default version
    echo "do nothing"
}
function  mount_iso_win() {
    echo "do nothing"
}
function setup_tftp_folder() {
    echo "do nothing"
}
function setup_kickstart_service() {
    echo "do nothing"
}
function umount_iso_win() {
    echo "do nothing"
}
function stop_tftp_win() {
    echo "do nothing"
}

# overwirtten version 
function create_vm_vbox(){

    VBoxManage createvm --name ${NAME} --ostype ${TYPE} --register

    # NIC Type includes :  [--nictype<1-N> Am79C970A|Am79C973|82540EM|82543GC|82545EM|virtio]
    # OS type get from commmand : VBoxMange list ostypes

    # WinXP Notes: 
    # 1.) NIC must Am79C973
    # 2.) storage muse IDE
         
    VBoxManage modifyvm ${NAME} \
        --vram 24 \
        --accelerate3d off \
        --memory 512 \
        --usb off \
        --audio none \
        --boot1 disk --boot2 net --boot3 none --boot4 none \
        --nictype1 Am79C973 --nic1 nat --natnet1 "${NATNET}" \
        --nictype2 virtio \
        --nictype3 virtio \
        --nictype4 virtio \
        --acpi on --ioapic off \
        --chipset piix3 \
        --rtcuseutc on \
        --hpet on \
        --bioslogofadein off \
        --bioslogofadeout off \
        --bioslogodisplaytime 0 \
        --biosbootmenu disabled

    VBoxManage storagectl ${NAME} \
        --name IDE --add ide

    VBoxManage storageattach ${NAME} \
        --storagectl IDE --port 0 --device 0 --type hdd --medium "${HDD}"
    VBoxManage storageattach ${NAME} \
        --storagectl IDE --port 1 --device 0 --type dvddrive --medium "${GUESTADDITIONS}"

    VBoxManage storagectl ${NAME} \
        --name "Floppy" --add floppy
    VBoxManage storageattach $NAME --storagectl "Floppy" --port 0 --device 0 --type fdd --medium "${FLOPPY}"

    VBoxManage setextradata ${NAME} "VBoxInternal/Devices/pcbios/0/Config/BiosRom" "${PCBIOS_BIN}"
}

# no need to do this, since winnt.sif is not work in the case
function create_unattened_floppy(){
    dd bs=512 count=2880 if=/dev/zero of=~/works/floppy01.img
    /sbin/mkfs.msdos ~/works/floppy01.img
    mount -o loop ~/works/floppy01.img /mnt
    cp winnt.sif /mnt
}

# See FAQ 7 in http://reboot.pro/topic/15593-faqs-and-how-tos/ 
function modify_vhd(){
    start "${DEVIO}" shm:vhd1 "${VHD_FILE}"
    #test -d vhd_mount || mkdir vhd_mount
    imdisk -a -t proxy -o shm -f vhd1 -m vhd_mount

    #cat ./vhd_mount/Sysprep/sysprep.inf

cat <<EOF >./vhd_mount/Sysprep/sysprep.inf
;SetupMgrTag
[Unattended]
    UnattendMode=FullUnattended
    OemSkipEula=Yes
    InstallFilesPath=C:\sysprep\i386
    TargetPath=\WINDOWS
    Repartition = Yes
    UnattendSwitch = Yes
    DriverSigningPolicy = Ignore
    WaitForReboot = No

[GuiUnattended]
    AdminPassword="123456"
    EncryptedAdminPassword=NO
    OEMSkipRegional=1
    TimeZone=210
    OemSkipWelcome=1
    AutoLogon=Yes
    AutoLogonCount=1

[UserData]
    ProductKey=RB277-9WQ3D-W4CCX-3383C-7389Q
    FullName="Windows XP Mode"
    OrgName="test"
    ComputerName="test2"


[Identification]
    JoinWorkgroup=WORKGROUP

[Networking]
    InstallDefaultComponents=Yes

[Branding]
    BrandIEUsingUnattended=Yes

[Proxy]
    Proxy_Enable=0
    Use_Same_Proxy=0

[GuiRunOnce]
    ;Setup 
    Command0="%systemdrive%\install.cmd"

[sysprepcleanup]
EOF

cat <<EOF >./vhd_mount/install.cmd
@echo off
echo "Install vbox gusest addtions..."
start /wait D:\VBoxWindowsAdditions.exe /S
echo "... Done"
echo "Stop Automatic Updates..."
sc stop wuauserv
sc config wuauserv start= disabled
echo "Stop Security Center..."
sc stop wscsvc
sc config wscsvc start= disabled
echo "... Done"

@rem ---------------------------------------------
@rem Best Performance
@rem ---------------------------------------------

@rem   [HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\VisualFXSetting]
@rem   best performance
@rem   0 = Let Windows choose what's best for my computer
@rem   1 = Adjust for best appearance
@rem   2 = Adjust for best performance
@rem   3 = Custom 
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects /v VisualFXSetting /t REG_DWORD /d 2 /f

@rem   [HKCU\Software\Microsoft\Windows\CurrentVersion\ThemeManager]
@rem   Use visual styles on windows and buttons (0=off 1=on) 
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\ThemeManager /v ThemeActive /t REG_SZ /d 0 /f
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\ThemeManager /v LoadedBefore /f
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\ThemeManager /v LastUserLangID /f
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\ThemeManager /v DllName /f
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\ThemeManager /v SizeName /f

@rem   [HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
@rem   Use common tasks in folders (0=off 1=on) 
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v WebView /t REG_DWORD /d 0 /f 
@rem   Show translucent selection rectangle (0=off 1=on)
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v ListviewAlphaSelect /t REG_DWORD /d 0 /f
@rem   Use drop shadows for icon labels on the desktop (0=off 1=on)
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v ListviewShadow /t REG_DWORD /d 0 /f
@rem   Use a background image for each folder type (0=off 1=on)
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v ListviewWatermark /t REG_DWORD /d 0 /f
@rem   Slide taskbar buttons (0=off 1=on)
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v TaskbarAnimations /t REG_DWORD /d 0 /f

@rem   [HKCU\Control Panel\Desktop\WindowMetrics]
@rem   Animate windows when minimizing and maximizing (0=off 1=on)
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f

@rem   [HKCU\Control Panel\Desktop]
@rem   Show window contents while dragging (0=off 1=on)
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 0 /f
@rem   Smooth edges of screen fonts (0=off 2=on)
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 0 /f

@rem   Smooth scroll list boxes
@rem   Slide open combo boxes
@rem   Fade or slide menus into view
@rem   Show shadows under mouse pointer
@rem   Fade or slide tooltips into view
@rem   Fade out menu items after clicking
@rem   Show shadows under menus
@rem   (All off = 90,12,01,80   All on = 9e,3e,05,80)
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 90120180 /f

@rem   [HKCU\Control Panel\Appearance]

reg add "HKCU\Control Panel\Appearance" /v Current /t REG_SZ /d "Windows Standard" /f
reg add "HKCU\Control Panel\Appearance" /v NewCurrent /t REG_SZ /d "Windows Standard" /f

echo "Reboot..."
shutdown -r -t 0
EOF
    cp 
    imdisk -d -m vhd_mount
    #test -d vhd_mount && rmdir vhd_mount
}

function extract_vhd(){
    test -f ${VHD_FILE} && echo "remove existed ${VHD_FILE}"; rm -f ${VHD_FILE};
    echo "extract xpm from ${XPMODE_EXE_FILE}"
    7z e ${XPMODE_EXE_FILE} sources/xpm -o$(to_win_path2 ${VHD_LOC}) -y 2>&1>NUL
    echo "extract VirtualXPVHD from xpm"
    7z e ${VHD_LOC}/xpm VirtualXPVHD -o$(to_win_path2 ${VHD_LOC}) -y 2>&1>NUL
    echo "remove xpm file"
    rm -f ${VHD_LOC}/xpm
}

function main(){
    main_template
}
function clean(){
    VBoxManage showvminfo ${NAME} --machinereadable|grep ^VMState=\"poweroff\"
    if [[ $? -eq 1 ]]; then
        echo "try to shutdown ${NAME}"
        VBoxManage controlvm ${NAME} poweroff
        sleep 1
    fi
    VBoxManage storageattach ${NAME} \
        --storagectl IDE --port 0 --device 0 --type hdd --medium none 
    VBoxManage unregistervm ${NAME} --delete
}

function gen_tweak_exe(){

cat <<"EOF" > ./tweak_xp.au3
;#NoTrayIcon
#include <Constants.au3>
#include <Debug.au3>
#include <GuiConstants.au3>
#include <GuiButton.au3>
#include <GuiListView.au3>
#include <WinAPI.au3>

Opt("WinTitleMatchMode", 4)

Const $sTitleMain = "[CLASS:#32770; TITLE:System Properties]"
Const $sTitlePerf = "[CLASS:#32770; TITLE:Performance Options]"
Const $sTitleRstr = "[CLASS:#32770; TITLE:System Restore]"
Const $sTitleRmtAsst = "[CLASS:#32770; TITLE:Remote Assistance Settings]"
Const $sTitleTaskBar = "[CLASS:#32770; TITLE:Taskbar and Start Menu Properties]"

Const $sSysdmCplAdv = "control sysdm.cpl,,3"
Const $sSysdmCplRstr = "control sysdm.cpl,,4"
Const $sSysdmCplAtUpd = "control sysdm.cpl,,5"
Const $sSysdmCplRmot = "control sysdm.cpl,,6"

Const $sDll32Folder ="rundll32.exe shell32.dll,Options_RunDLL 0"
Const $sDll32TaskBar ="rundll32.exe shell32.dll,Options_RunDLL 1"

Global $hWinMain ; handle for main

_DebugSetup("Debug Console", True) ; start displaying debug environment


;=======================================================================
; Wait for Act
;=======================================================================
Func WaitAct ( $vTitle )
    Local  $iReturn = WinWaitActive($vTitle)
    if $iReturn=0 then
        _DebugOut("Could not attach to dialog"&$vTitle);
    exit
    endif
    Return $iReturn
EndFunc   ;==>WaitAct

Func Button_Checked ($hMain, $sButtonTitle)
    Local $hButtionCheckBox = ControlGetHandle($hMain, "", $sButtonTitle)
    _DebugOut("Get Handle checkbox "&$hButtionCheckBox)
    _DebugOut("_GUICtrlButton_GetCheck = "&_GUICtrlButton_GetCheck($hButtionCheckBox))
    _DebugOut("_GUICtrlButton_GetState = "&_GUICtrlButton_GetState($hButtionCheckBox))
    _DebugOut("_GUICtrlButton_GetText = "&_GUICtrlButton_GetText($hButtionCheckBox))
    _DebugOut("_GUICtrlListView_GetItemCount = "&_GUICtrlListView_GetItemCount($hButtionCheckBox))
    _DebugOut("_GUICtrlListView_GetItemChecked = "&_GUICtrlListView_GetItemChecked($hButtionCheckBox, 0))
    _DebugOut("_GUICtrlListView_GetItemChecked = "&_GUICtrlListView_GetItemChecked($hButtionCheckBox, 1))
    _DebugOut("_GUICtrlListView_GetGroupInfo = "&_GUICtrlListView_GetGroupInfo($hButtionCheckBox, 0))
    _DebugOut("_GUICtrlListView_GetGroupInfo = "&_GUICtrlListView_GetGroupInfo($hButtionCheckBox, 1))

Local $hTablCountrol
    local $iCount = ControlListView("[CLASS:#32770; TITLE:Taskbar and Start Menu Properties]","","[CLASS:SysTabControl32; INSTANCE:1]","GetItemCount")
    _DebugOut("ControlListView -> GetItemCount = "&$iCount)

    if _GUICtrlButton_GetCheck($hButtionCheckBox) = $GUI_CHECKED then
        return TRUE
    else
        return FALSE
    endif
EndFunc ;==>Buttion_Checked

;=======================================================================
; Adjust For Best Performance
;=======================================================================
;Opens the System Properties window and chooses the 4rd tab
;Note, starts from 0, the 3 is the "Advanced" tab

Func Apply_BestPerformance()
    Run($sSysdmCplAdv)
    _DebugOut("----------------------------------------")
    _DebugOut("Run "&$sSysdmCplAdv)

    WaitAct($sTitleMain)

    Send("!s") ;Performance -> "Settings"
    _DebugOut("send Alt-S")


    WaitAct($sTitlePerf)
    Send("!p") ;"Adjust for best performance"
    _DebugOut("send Alt-P")

    ;click on "OK" button under Performance Options tab
    WaitAct($sTitlePerf)
    Send("{ENTER}")
    _DebugOut("send ENTER -> OK")
    ;ControlClick("","","Button5")
    ;_DebugOut("click Button5 -> OK")

    ;click on "OK" button under System Properties page
    WaitAct($sTitleMain)
    ControlClick("","","Button9")
    _DebugOut("click Button9 -> OK -> EXIT")
EndFunc

;=======================================================================
; Trun Off System Restore
;=======================================================================
Func Disable_SystemRestore()
    Run($sSysdmCplRstr); Open "System Restore" tab
    _DebugOut("----------------------------------------")
    _DebugOut("Run "&$sSysdmCplRstr)

    WaitAct($sTitleMain)
    $hWinMain=WinGetHandle($sTitleMain)
    _DebugOut("Get Handle main "&$hWinMain)

    $hCheckBox = ControlGetHandle($hWinMain, "", "[CLASS:Button; INSTANCE:1]")
    _DebugOut("Get Handle checkbox "&$hCheckBox)

    If Not _GUICtrlButton_GetCheck($hCheckBox) = $GUI_CHECKED Then
        ;MsgBox($MB_SYSTEMMODAL, "AutoIt Debug", "check box not checked, try to do turn off system restore")
        WaitAct($sTitleMain)
        ControlClick("","","Button1")
        _DebugOut("click Button1 -> Check the turn off system restore")

        WaitAct($sTitleMain)
        ControlClick("","","Button5");click on "OK" button under System Properties page
        _DebugOut("click Button5 -> OK ")

        WaitAct($sTitleRstr)
        ControlClick("","","Button1");click on "Yes" button under System Restore Confrom diag
        _DebugOut("click Button1 -> YES to comfirm")

    endif
    WaitAct($sTitleMain)
    ControlClick("","","Button5");click on "OK" button under System Properties page
    _DebugOut("click Button5 -> OK -> EXIT")
EndFunc

;=======================================================================
; Trun Off Auto Update
;=======================================================================
Func Disable_AutoUpdate()
    Run($sSysdmCplAtUpd)
    _DebugOut("----------------------------------------")
    _DebugOut("Run "&$sSysdmCplAtUpd)
    WaitAct($sTitleMain)
    Send("!T")
    _DebugOut("send Alt-T -> Trun off Auto update")
    WaitAct($sTitleMain)
    Send("{ENTER}")
    _DebugOut("send ENTER -> OK -> EXIT")
EndFunc

;=======================================================================
; Disable Remote Assistance
;=======================================================================
Func Disable_RemoteAssist()
    Run($sSysdmCplRmot)
    _DebugOut("----------------------------------------")
    _DebugOut("Run "&$sSysdmCplRmot)
    WaitAct($sTitleMain)
    $hWinMain=WinGetHandle($sTitleMain)
    _DebugOut("Get Handle main "&$hWinMain)

    ;-----------------------------------------------------------------
    ;Note Button_checked():
    ;  Button_checked() function not work with the grouped checkbox button
    ;  in remote assistance selection. I don't how to do this.
    ;Workaround:
    ;  use the tick of send alt-v to open advanced remote assit setting
    ;  window first and test if the setting window is open, if open, means
    ;  the box checked, otherwise it unchecked.
    ;TODO:
    ;  look at $BS_GROUPBOX in <ButtonConstants.au3>
    ;  https://opensource.ncsa.illinois.edu/stash/projects/POL/repos/menu-mining/browse/menu-mining/autoit-scripts/ExtractControlsFunc.au3
    ;  if got time
    ;  
    ;-----------------------------------------------------------------
    if not Button_Checked($hWinMain,"[CLASS:Button; INSTANCE:5]") then
        WaitAct($sTitleMain)
    ;    Send("!R")
    ;    _DebugOut("send ALT-R first -> Don't know if it checked")
        WaitAct($sTitleMain)
        Send("!v")
        _DebugOut("send ALT-v -> try to open remove assist setting")
        if WinWaitActive($sTitleRmtAsst,"",1) = 0 then
            _DebugOut("advanced setting window not opened -> the remote assist is disabled by default")
        else
            _DebugOut("advanced setting window opened")
            ControlClick("","","Button2") ; cancle
            _DebugOut("click Button2-> cancle -> to exit remote assist advanced setting window")
            WaitAct($sTitleMain)
            Send("!R") ; again
            _DebugOut("send ALT-R -> unchecked -> to disable remote assist")
        endif
    endif

    WaitAct($sTitleMain)
    ControlClick("","","Button7")
    _DebugOut("click Button7 -> OK -> EXIT")
EndFunc


;Apply_BestPerformance()
;Disable_SystemRestore()
;Disable_AutoUpdate()
;Disable_RemoteAssist()


;=======================================================================
; Task Bar and Start up 
; NOTE:
; Still can't let button ctrl work as a list of GroupBox or ListView, 
; so dn't use it, instead by using _QuickLaunch_SetState() method
;=======================================================================
Func Set_TaskBar()
    RUN($sDll32TaskBar)
    _DebugOut("----------------------------------------")
    _DebugOut("Run "&$sDll32TaskBar)
    WaitAct($sTitleTaskBar)
    $hWinMain=WinGetHandle($sTitleTaskBar)
    _DebugOut("Get Handle main "&$hWinMain)

    $hBigButton=ControlGetHandle($hWinMain, "", "[CLASS:Button; INSTANCE:9]")
    $iLong = _WinAPI_GetWindowLong($hBigButton, $GWL_STYLE)
    _DebugOut("Get Handle big button "&$hBigButton)
    _DebugOut("Get Handle big button iLong "&$iLong)
    Button_Checked($hWinMain,"[CLASS:Button; INSTANCE:9]")
    send("!Q") ; send alt-Q to click "show quick lanuch", the problem is don't know if checked or not.
    Button_Checked($hWinMain,"[CLASS:Button; INSTANCE:9]")
EndFunc
;Set_TaskBar()

;===============================================================================
; From : http://www.autoitscript.com/forum/topic/95846-show-quick-launch/
; Function Name:    QuickLaunch_SetState
; Description:      Enable/disable the quick launch toolbar
; Parameter(s):     $fState - Specifies whether to enable or disable the quick launch toolbar.
;                       True (1) = toolbar is enabled
;                       False (0) = toolbar is disabled
; Requirement(s):   Windows 2000 or XP
; Return Value(s):  Success - Return value from _SendMessage
;                   Failure - @error is set
;                   @error  - 1 = Invalid $fState, 2 = Unable to get handle for Shell_TrayWnd
; Author(s):        Bob Anthony (big_daddy)
;
;===============================================================================
;
Func QuickLaunch_SetState($fState)
    ; Already disclared in <WindowsConstants.au3>
    ;Const $WM_USER = 0X400
    ;See http://msdn.microsoft.com/en-us/library/windows/desktop/ms644931(v=vs.85).aspx
    ;social.technet./Forums/en-US/c56caaff-90c0-4755-9ce0-29400b43b89c/enable-quick-launch-toolbar-powershell
    ;BTW, where is the document for the migic code 237?, anyway it works on XP
    Const $WMTRAY_TOGGLEQL = ($WM_USER + 237)

    If $fState <> 0 And $fState <> 1 Then Return SetError(1, 0, 0)

    $hTrayWnd = WinGetHandle("[CLASS:Shell_TrayWnd]")
    If @error Then Return SetError(2, 0, 0)

    Return _SendMessage($hTrayWnd, $WMTRAY_TOGGLEQL, 0, $fState)
EndFunc   ;==>_QuickLaunch_SetState

;Func _QuickLaunch_AutoSize()
;    Local $iIndex = 0
;   Local $hTaskBar = _WinAPI_FindWindow("Shell_TrayWnd", "")
;   Local $hRebar = ControlGetHandle($hTaskBar, "", "ReBarWindow321")
;    _GUICtrlRebar_MinimizeBand($hRebar, $iIndex)
;    _GUICtrlRebar_MaximizeBand($hRebar, $iIndex, True)
;EndFunc   ;==>_QuickLaunch_AutoSize


QuickLaunch_SetState(True)
;_QuickLaunch_AutoSize()

EOF
    au3_to_exe "tweak_xp.au3" "tweak_xp.exe"
}

function au3_to_exe(){
    local au3_file="$1"
    local exe_file="$2"
    #echo ${au3_file} ${exe_file}
    gen_tweak_cmd="$(to_win_path ${AUTOIT}) /in $(to_win_path $(pwd))\\$au3_file /out $(to_win_path $(pwd))\\$exe_file /comp 4 /pack"
    #echo "$gen_tweak_cmd"
    start cmd /k "$gen_tweak_cmd && exit"
}

NAME=windowsxp-sp3-xp_mode
TYPE=WindowsXP
GUESTADDITIONS="../../vagrant-centos/isos/VBoxGuestAdditions_4.3.10.iso"
HDD="/c/Users/yidwu/Downloads/VirtualXPVHD"
INSTALLER="/d/ISO/windows/WinXP-SP3.iso"
KS_CFG="ks_centos.cfg"

VHD_LOC="${HOME}/Downloads"
VHD_FILE_NAME="VirtualXPVHD"
VHD_FILE="${VHD_LOC}/${VHD_FILE_NAME}"

XPMODE_EXE_LOC="/d/ISO/windows/"
XPMODE_EXE_NAME="WindowsXPMode_N_en-us.exe"
XPMODE_EXE_FILE="${XPMODE_EXE_LOC}/${XPMODE_EXE_NAME}"

FLOPPY="${HOME}\Downloads\floppy01.img"

PCBIOS_BIN="${HOME}\Downloads\pcbios.bin"

DEVIO="${HOME}\Downloads\devio"

AUTOIT="${HOME}\Downloads\autoit-v3\install\Aut2Exe\Aut2exe"


if [[ -z "$1" ]]; then
    clean
    extract_vhd
    modify_vhd
    main
elif [[ "$1" == "main" ]]; then
    main
elif [[ "$1" == "clean" ]]; then
    clean
elif [[ "$1" == "extract" ]]; then
    extract_vhd
elif [[ "$1" == "modvhd" ]]; then
    modify_vhd
elif [[ "$1" == "genexe" ]]; then
    gen_tweak_exe
fi

