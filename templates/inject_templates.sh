user="$1"
pass="$2"

# 1.15
base_command="hammer --verify-ssl false -u $user -p $pass"
# 1.14 or earlier
# base_command="hammer -u $user -p $pass"

# 1. Add new architecture x64
$base_command architecture create --name x64

# 2. Add new operating system Name:Windows, Major:6, Minor:3, Family:Windows, RootPassHash:Base64, Architectures:x64
$base_command os create --architectures x64 --family Windows --name Windows --description "Windows Server 2016" --password-hash Base64 --major 10 --minor 0
$base_command os create --architectures x64,i386 --family Windows --name Windows --description "Windows Server 2012 R2" --password-hash Base64 --major 6 --minor 3
$base_command os create --architectures x64,i386 --family Windows --name Windows --description "Windows Server 2012" --password-hash Base64 --major 6 --minor 2
$base_command os create --architectures x64,i386 --family Windows --name Windows --description "Windows Server 2008 R2" --password-hash Base64 --major 6 --minor 1
$base_command os create --architectures x64,i386 --family Windows --name Windows --description "Windows Server 2008" --password-hash Base64 --major 6 --minor 0

# 3. Add templates
operatingsystems='"Windows Server 2008 R2","Windows Server 2012 R2","Windows Server 2016"'
$base_command template create --operatingsystems "Windows Server 2008","Windows Server 2008 R2","Windows Server 2012","Windows Server 2012 R2","Windows Server 2016" --file windows_default_finish.erb --name "Windows default finish" --type finish
$base_command template create --operatingsystems "Windows Server 2008","Windows Server 2008 R2","Windows Server 2012","Windows Server 2012 R2","Windows Server 2016" --file windows_default_provision.erb --name  "Windows default" --type "provision"
$base_command template create --operatingsystems "Windows Server 2008","Windows Server 2008 R2","Windows Server 2012","Windows Server 2012 R2","Windows Server 2016" --file windows_default_pxelinux.erb --name "Windows default PXELinux" --type "PXELinux"
$base_command template create --operatingsystems "Windows Server 2008","Windows Server 2008 R2","Windows Server 2012","Windows Server 2012 R2","Windows Server 2016" --file windows_default_script.erb --name "Windows default script" --type "script"
$base_command template create --operatingsystems "Windows Server 2008","Windows Server 2008 R2","Windows Server 2012","Windows Server 2012 R2","Windows Server 2016" --file snip_windows_extra_finish_commands.erb --name "windows_extra_finish_commands" --type "snippet"
$base_command template create --operatingsystems "Windows Server 2008","Windows Server 2008 R2","Windows Server 2012","Windows Server 2012 R2","Windows Server 2016" --file snip_windows_local_users.xml.erb --name "windows_local_users" --type "snippet"
$base_command template create --operatingsystems "Windows Server 2008","Windows Server 2008 R2","Windows Server 2012","Windows Server 2012 R2","Windows Server 2016" --file snip_windows_ou_from_hostgroup.erb --name "windows_ou_from_hostgroup" --type "snippet"
$base_command template create --operatingsystems "Windows Server 2008","Windows Server 2008 R2","Windows Server 2012","Windows Server 2012 R2","Windows Server 2016" --file windows_default_user_data.erb --name "Windows default user data" --type "user_data"
$base_command template create --operatingsystems "Windows Server 2008","Windows Server 2008 R2","Windows Server 2012","Windows Server 2012 R2","Windows Server 2016" --file snip_windows_networking_setup.erb --name "windows_networking_setup" --type "snippet"

# 4. Add partition table and associate it
$base_command partition-table create --os-family Windows --name "Windows default diskpart" --file "windows_default_diskpart.erb"  --operatingsystems "Windows Server 2008","Windows Server 2008 R2","Windows Server 2012","Windows Server 2012 R2","Windows Server 2016"

# 5. Get template IDs
finish_id=$($base_command template list| grep "Windows default finish" | grep -o '^[0-9]*')
provision_id=$($base_command template list| grep "Windows default" | grep -o '^[0-9]*')
pxelinux_id=$($base_command template list| grep "Windows default PXELinux" | grep -o '^[0-9]*')
script_id=$($base_command template list| grep "Windows default script" | grep -o '^[0-9]*')
user_data_id=$($base_command template list| grep "Windows default user data" | grep -o '^[0-9]*')
template_ids=( $finish_id $provision_id $pxelinux_id $script_id $user_data_id )
echo $template_ids

# 6. Get OS ids
w2008_id=$($base_command os list | grep "Windows Server 2008" | grep -v "R2" | grep -o '^[0-9]*')
w2008r2_id=$($base_command os list | grep "Windows Server 2008 R2" | grep -o '^[0-9]*')
w2012_id=$($base_command os list | grep "Windows Server 2012"  | grep -v "R2" | grep -o '^[0-9]*')
w2012r2_id=$($base_command os list | grep "Windows Server 2012 R2" | grep -o '^[0-9]*')
w2016_id=$($base_command os list | grep "Windows Server 2016" | grep -o '^[0-9]*')
os_ids=($w2008_id $w2008r2_id $w2012_id $w2012r2_id $w2016_id)
echo $os_ids

# 7. Set default templates for each os
for os_id in "${os_ids[@]}"; do
  for template_id in ${template_ids[@]}; do
    $base_command os set-default-template --config-template-id $template_id --id $os_id
  done
done
