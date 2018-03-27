# Configuring Foreman
Now as you have your WIM images ready, it's time to configure your foreman installation. Make sure you meet the prerequisites.

### Tasks break down
- Download wimboot
- Change / add a new Architecture and OS
- Add provision templates
- Add installation media
- Add partition table
- Add parameters
- Link provisioning templates to OS
- Do a lot of testing

### Hammer automation
Moving templates folder to the foreman server and running `sh inject_hammer.sh username password` will automaticlly do steps II,III,V,VI using hammer cli  for versions:
- Windows Server 2008
- Windows Server 2008 R2
- Windows Server 2012
- Windows Server 2012 R2
- Windows Server 2016

Test: Partition templates added automaticlly to the OS  
Steps left: I, IV, VII, VIII

## I. Download wimboot
Start simple:
- Add [wimboot](http://git.ipxe.org/releases/wimboot/wimboot-latest.zip) bootloader to `/var/lib/tftpboot/boot/` on your PXE server.

## II. Architecture and OS
In _Hosts -> Architectures_ add a new architecture:

- Name: `x64`

Add a new OS in _Hosts -> Operating systems_ if needed.
If you already have windows hosts and puppet, the correct OS and architecture have been auto created already.
This example covers Windows 8.1 / Windows Server 2012R2.

![Add new OS](img/forman_os.png "Adding Windows 8 OS in Foreman")

- Name: `windows`
- Major: `6`
- Minor: `3`
- OS family: `windows`
- Description: `Windows8`
- Root password hash: `Base64`
- Architectures: `x64`

### Root passwords and encoding
Take special care to __Root password hash = `Base64`__. The templates do not render correctly if this is set otherwise.
Also, changing the encoding does not [apply do existing hosts](http://theforeman.org/manuals/1.9/index.html#3.5.2ConfigurationOptions)

## III. Add provision templates
Head to _Hosts -> Provisioning Templates -> New_ and create a template for each of the files in `./templates`.
You can copy / paste them or upload the file. Assign each of those templates to your Windows OS (does not apply to snippets).
The naming of the templates is a suggestion and up to you. Keep in mind, this does __not__ apply to snippets! There, the name is important.

Since it is very likely you will need to edit these templates to your needs read about [Foreman Template Writing](http://projects.theforeman.org/projects/foreman/wiki/TemplateWriting)

### Required templates
This part will explain about each template, the templates are ordered by the execution time
#### Windows default PXELinux
- Name: `Windows default PXELinux`
- Type: `PXELinux template`
- Description: The PXELinux file, tells the machine to go up from wimboot

**Note**: This file contains hardcoded location of the bcd, bootsdi and bootwim files because there is no way to get this parameters from `windows.rb` in foreman using safemode.

#### Windows default script
- Name: `Windows default script`
- Type: `Script template`
- Description: The first batch script to run, running from WinPE
- Contains:
  - Downloading the wim file and installing the right os using `wimImageName` parameter
  - Configuring the right boot sector
  - Downloading drivers from drivers folder in the OS url
  - Downloading extras from extras folder in the OS url
  - Downloading unattend.xml (Calling the provision template and saving it to unattend.xml)
  - Downloading the finish template (Calling the finish template and saving it to foreman-finish.bat)
  - Copy necessary tools from the WinPE image to the OS folder (wget64.exe > wget.exe, sdelete.exe) todo: add nvspbind, move the files to temporary folder, and delete at the end
  - Moving foreman-finish script to SetupComplete.cmd script, including output redirection to c:\foreman.log (if `foremanDebug` is true)
  - Downloading joinDomain.ps1 (Calling the user data template and saving it to joinDomain.ps1)
  - Applying the unattend.xml file
  - Applying the drivers

__Note:__ To get the download folders nicely, the [`wget64.exe`](https://www.gnu.org/software/wget/manual/wget.html) commands in this template might need tweaking. This could
especially be necessary if you intend to use the `extraFinishCommands` snippet.
Eg, `--cut-dirs=3` would cut the first three directories form the download path when saving locally.
This way `http://winmirror.domain.com/pub/win81x64/extras/puppet.msi` will be stripped of `pub/win81x64/extras` and download to `puppet.msi`.

#### Windows default
- Name: `Windows default`
- Type: `Provisioning template`
- Description: The unattend.xml file used to make sysprep
- Contains:
  - Configuring the given `systemLocale` (default: en-US), `systemUILanguage` (default: en-US), `systemTimeZone` (default: GMT Standard Time)
  - Using `wimImageName` to decide the type of the OS
  - Using `administratorPassword` variable (**NOT root_pass**) to configure the local administrator password, this part is clear text and the unattend file deleted at the `Windows default finish` template using sdelete
  - Containing `windows_local_users` snippet (explained later)
  - Setting `windowsLicenseOwner` and `windowsLicenseOrganization` if given
  - Setting `windowsLicenseKey` if present
  - Setting computer name.
  - Disabling firewall (Domain, private and public profiles)
  - Allowing TS connection

#### Windows default finish
- Name: `Windows default finish`
- Type: `Finish template`
- Description: Generates a batch file that configuring your Windows host after it is up and running
- Contains:  
  - Activating local Administrator account if localAdminAccountDisabled is not present / false
  - Configuring provisioning network on working through it (including static configuration) todo wip: using `windows_networking_setup` + teaming...
  - Disable IPv6 using disableIPv6 flag
  - Configuring ntp server if present (ntpServer parameter)
  - Calling joinDomain.ps1 script (`Windows default user data`) if `domainJoinAccount` and `domainJoinAccount` are present
  - Deleting all use filed with sdelete unless `foreman_debug` marked as true
  - Calling `windows_extra_finish_commands` snippet if present (it should be present)
  - Calling foreman built url in order to mark the host as Installed unless `rundeckBuilt` is true (`windows_extra_finish_commands` handles this case)

### Optional templates
#### Wimaging joinDomain.ps1
- Name: `Wimaging joinDomain.ps1`
- Type: `User data template`

#### Wimaging local users
- Name: `Wimaging local users`
- Type: Snippet

__Note:__ This snippet creates extra users in the unattended stage.
This may be very useful for debugging early stages of your deployment; since you
can find yourself locked out of the newly provisioned host.

Microsoft did not really care for passwords in unattend.xml files; so it does not really matter if you use
`<PlainText>true</PlainText>` or not.
If you want to disguise your password, you could add a host parameter `localUserPassword` and use the following ruby/erb function with `<PlainText>false</PlainText>`:

```ruby
<%= Base64.encode64(Encoding::Converter.new("UTF-8", "UTF-16LE",:undef => nil).convert(@host.params['localUserPassword']+"Password")).delete!("\n").chomp -%>
```

Note,  the string `Password` is appended your passwords. You can try this out with by generating an unattend.xml containing local users using WAIK.

#### Wimaging extraFinishCommands
- Name: `Wimaging extraFinishCommands`
- Type: Snippet

__Note:__ The commands here are executed at the last stage just before finishing host building.
Make sure they get executed in a synchronous way (eg. do not run in background like msiexec).
Otherwise the following reboot might kill them.

#### Wimaging OU from Hostgroup
- Name: `Wimaging OU from Hostgroup`
- Type: Snippet

__Note__: This snippet may be used to generate the computer OU from the host's hostgroup and domain.

Example: Imagine host `example` in domain `ad.corp.com` and in hostgroup `servers/windows/databases`.
The snippet generates the OU path:
`OU=databases,OU=windows,OU=servers,DC=ad,DC=corp,DC=com`. Optionally, set the host parameter `computerOuSuffix` to add some arbitrary OU at the end.

## IV. Add installation media
For each of your Windows versions add a new installation media pointing to the root of the folder.
Eg, `http://winmirror.domain.com/pub/win81x64`. Assign them to your operatingsystem.

## V. Add partition table
Add the diskpart script from `./templates/wimaging_partition_table.erb` as new partition table. Assign it to your windows OS.

## VI. Define templates
Link all the created templates as well as the installation media and partition table to the OS:

- Head to your OS, then provisioning
- Select the template from each kind from the drop down list
- In partition tables, select `Wimaging default`
- In installation media, check the appropriate installation media added above.

![Link templates to OS](img/forman_os_templates.png "Linking Windows 8 OS in Foreman")

## VII. Add Parameters
To render the the templates correctly, some parameters need to be added. The can be globals, or put them on
a hostgroup. Most of them make the most sense as parameter on the the OS. Also, almost none are
required and have defaults. For the most up to date desciption see the template itself.

### Important parameters
#### Required
- `windowsLicenseKey`: Valid Windows license key or generic KMS key
- `windowsLicenseOwner`: Legal owner of the Windows license key
- `wimImageName`: WIM image to install from a multi image install.wim file.

#### Optional
The following parameters are only applied if they exist. Some, like `domainAdminAccount` and `domainAdminAccountPasswd` require each other, tough.
- `systemLocale`: en-US
- `systemUILanguage`: en-US
- `systemTimeZone`: Pacific Standard Time - see [MS TimeZone Naming](https://msdn.microsoft.com/en-us/library/ms912391%28v=winembedded.11%29.aspx)
- `localAdminiAccountDisabled`: false - will keep the local administrator account disabled (default windows)
- `ntpSever`: time.windows.com,other.time.server - ntp server to use
- `domainJoinAccount`: administrator@domain.com - use this account to join the computer to a domain
- `domainJoinAccountPassword`: Pa55w@rd - Password for the domain Admin account
- `computerOU`: OU=Computers,CN=domain,CN=com - Place the computer account in specified Organizational Unit
- `computerOuSuffix`: Used if `computerOU` is not present to generate the computer OU from hostgroup and hostdomain. `computerOU` takes precedence! Note, the OU must still be manually created in active directory.
- `computerDomain`: domain.com # domain to join
- `disableIPv6`: Allows you to disable IPv6 through the registry
- `foreman_debug`: Enables alot of debug logs, doesn't remove installations files, this option is recommended **only** for debug

#### Optional - Rundeck
- `runRundeck`: Call rundeck at the end of the finish script, make sure you wait till the host will end the boot which allows the server to apply GPO settings (such as enable WinRM), the host name will be sent through "hosts" argument
**Set these parameters only if `runRundeck` is true**
- `rundeckURL`: The URL or name (FQDN) of the Rundeck server, for example: https://www.rundeck.domain
- `rundeckJobId`: The job id of the rundeck job
- `rundeckAuthToken`: The authentication token of your Rundeck user
- `rundeckExtraArgString`: Not required, if you need to send more arguments to the Rundeck, for example: -environment hardware -server windows2012
- `rundeckBuilt`: Foreman built url will be sent to the rundeck as "built_url" parameters and won't be called within foreman templates, allows you to mark the host as built only after rundeck finished to run, for example, you can run ansible-playbook and at the end to call role that will mark the host as built, see this role for example: [win_foreman_built](https://github.com/LiranNis/win_foreman_built)
- If you don't want puppet to be installed, ensure you don't pick any Puppet Master when creating host

## VIII. Testing and Troubleshooting
The templates most likely need a lot of testing to work. This is not covered here; though some hints how to start. You should proceed in this order:

1. __Get your templates to render correctly__. Create a random `Bare Metal` host in the desired hostgroup for this purpose and make extensive use of foreman's excellent template __Preview__.
2. __Continue testing with VMs__ to test netbooting and basic installation
3. __Debug `peSetup.cmd`__ by pausing it at the send (remove the comment from `::PAUSE`). Then, use `Ctrl-C` to cancel the script altogether. This way you can debug the rendered `peSetup.cmd` quite nicely in WinPE (eg, `notepad peSetup.cmd`)
4. Use a manually installed host to test rendered snippets like `Wimaging extraFinishCommands` directly.
5. __Examine `C:\foreman.log.`__ - the output left from the finish script. Also, comment out the clean up stage in the finish script to examine and test the rendered scripts directly, requires `foreman_debug` to be true.
