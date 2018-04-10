user="$1"
pass="$2"

# 1.15
base_command="hammer --verify-ssl false -u $user -p $pass"
# 1.14 or earlier
# base_command="hammer -u $user -p $pass"

# 3. Export templates
$base_command template dump --name "Windows default finish"  > windows_default_finish.erb
$base_command template dump --name "Windows default"  > windows_default_provision.erb
$base_command template dump --name "Windows default PXELinux"  > windows_default_pxelinux.erb
$base_command template dump --name "Windows default script"  > windows_default_script.erb
$base_command template dump --name "windows_extra_finish_commands"  > snip_windows_extra_finish_commands.erb
$base_command template dump --name "windows_local_users"  > snip_windows_local_users.xml.erb
$base_command template dump --name "windows_ou_from_hostgroup"  > snip_windows_ou_from_hostgroup.erb
$base_command template dump --name "Windows default user data"  > windows_default_user_data.erb
$base_command template dump --name "windows_networking_setup"  > snip_windows_networking_setup.erb

# 4. Export partition table
$base_command partition-table dump --name "Windows default diskpart" > windows_default_diskpart.erb
