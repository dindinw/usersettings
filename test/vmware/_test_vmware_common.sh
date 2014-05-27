# 
VCENTER_IP="vcenter_ip"
VCENTER_USER="user"
VCENTER_PASS="password"

. ../../lib/core.sh
. func_vmware.sh
if [[ -f _CONFIG_OVERWRITE ]]; then . _CONFIG_OVERWRITE; fi