foreman-wimaging
================
I'm publishing my foreman templates that I use to provision Windows.

This allows to have flexible template-based opensource provisioning of Windows systems using Foreman & puppet.

### Prerequisites 
- Foreman 1.9 or patched [windows.rb](https://github.com/theforeman/foreman/commit/85e625447252ac1810a6e2bdabf03baeb3d4d56c)
- Recent version of foreman-proxy with patched [files](https://github.com/theforeman/smart-proxy/pull/258/files) for wimaging.

FEATURES:
- Template-based provisioning of Windows hosts
- Join domain
- Disable IPv6
- Run a rundeck job
- Send `foreman_url('built')` to rundeck as `built_url` in order to send finish at the end of the rundeck job
- Auto register in puppet - Needs testing after changes

TODO:
- Add option to enable Ansible in extraCommands
- userdata template

Source: [foreman-wimaging](https://github.com/kireevco/foreman-wimaging)
