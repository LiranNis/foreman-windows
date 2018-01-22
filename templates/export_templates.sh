user="$1"
pass="$2"

# 1.15
base_command="hammer --verify-ssl false -u $user -p $pass"
# 1.14 or earlier
# base_command="hammer -u $user -p $pass"

# 3. Export templates
$base_command template dump --name "Wimaging finish"  > wimaging_finish.erb
$base_command template dump --name "Wimaging provision"  > wimaging_provision_unattend.xml.erb
$base_command template dump --name "Wimaging PXELinux"  > wimaging_pxelinux.erb
$base_command template dump --name "Wimaging peSetup.cmd"  > wimaging_script_winpe_setup.erb
$base_command template dump --name "Wimaging extraFinishCommands"  > wimaging_snip_extra_finish_commands.erb
$base_command template dump --name "Wimaging local users"  > wimaging_snip_local_users.xml.erb
$base_command template dump --name "Wimaging OU from Hostgroup"  > wimaging_snip_ou_from_hostgroup.erb
$base_command template dump --name "Wimaging joinDomain.ps1"  > wimaging_userdata_joinDomain.ps1.erb
