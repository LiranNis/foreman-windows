user="$1"
pass="$2"

# 1. Add new architecture x64
hammer -u $user -p $pass architecture create --name x64
# 2. Add new operating system Name:Windows, Major:6, Minor:3, Family:Windows, RootPassHash:Base64, Architectures:x64
hammer -u $user -p $pass os create --architectures x64 --family Windows --name Windows --description "Windows Server 2016" --password-hash Base64 --major 10 --minor 0
hammer -u $user -p $pass os create --architectures x64,i386 --family Windows --name Windows --description "Windows Server 2012 R2" --password-hash Base64 --major 6 --minor 3
hammer -u $user -p $pass os create --architectures x64,i386 --family Windows --name Windows --description "Windows Server 2012" --password-hash Base64 --major 6 --minor 2
hammer -u $user -p $pass os create --architectures x64,i386 --family Windows --name Windows --description "Windows Server 2008 R2" --password-hash Base64 --major 6 --minor 1
hammer -u $user -p $pass os create --architectures x64,i386 --family Windows --name Windows --description "Windows Server 2008" --password-hash Base64 --major 6 --minor 0
# 3. Add templates and associate with windows
operatingsystems="Windows Server 2008 R2","Windows Server 2012 R2","Windows Server 2016"
hammer -u $user -p $pass template create --operatingsystems "Windows Server 2008 R2","Windows Server 2012 R2","Windows Server 2016" --file wimaging_finish.erb --name "Wimaging finish" --type finish 
hammer -u $user -p $pass template create --operatingsystems "Windows Server 2008 R2","Windows Server 2012 R2","Windows Server 2016" --file wimaging_provision_unattend.xml.erb --name  "Wimaging provision" --type "provision"
hammer -u $user -p $pass template create --operatingsystems "Windows Server 2008 R2","Windows Server 2012 R2","Windows Server 2016" --file wimaging_pxelinux.erb --name "Wimaging PXELinux" --type "PXELinux"
hammer -u $user -p $pass template create --operatingsystems "Windows Server 2008 R2","Windows Server 2012 R2","Windows Server 2016" --file wimaging_script_winpe_setup.erb --name "Wimaging peSetup.cmd" --type "script"
hammer -u $user -p $pass template create --operatingsystems "Windows Server 2008 R2","Windows Server 2012 R2","Windows Server 2016" --file wimaging_snip_extra_finish_commands.erb --name "Wimaging extraFinishCommands" --type "snippet"
hammer -u $user -p $pass template create --operatingsystems "Windows Server 2008 R2","Windows Server 2012 R2","Windows Server 2016" --file wimaging_snip_local_users.xml.erb --name "Wimaging local users" --type "snippet"
hammer -u $user -p $pass template create --operatingsystems "Windows Server 2008 R2","Windows Server 2012 R2","Windows Server 2016" --file wimaging_snip_ou_from_hostgroup.erb --name "Wimaging OU from Hostgroup" --type "snippet"
hammer -u $user -p $pass template create --operatingsystems "Windows Server 2008 R2","Windows Server 2012 R2","Windows Server 2016" --file wimaging_userdata_joinDomain.ps1.erb --name "Wimaging joinDomain.ps1" --type "user_data"
# 4. Add partition table and associate with windows
hammer -u $user -p $pass partition-table create --os-family Windows --name "Windows default" --file "wimaging_partition_table.erb"
