d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us
d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string packer-debian
d-i netcfg/get_domain string local

d-i passwd/root-login boolean false
d-i passwd/user-fullname string Automation
d-i passwd/username string ${username}
d-i passwd/user-password-crypted password ${password_hash}

d-i clock-setup/utc boolean true
d-i time/zone string UTC

d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic
d-i partman/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

tasksel tasksel/first multiselect standard, ssh-server
d-i pkgsel/include string sudo openssh-server open-vm-tools python3 cloud-init
d-i pkgsel/upgrade select safe-upgrade
popularity-contest popularity-contest/participate boolean false

d-i preseed/late_command string in-target /bin/sh -c "echo '${username} ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/90-${username}"; in-target chmod 440 /etc/sudoers.d/90-${username}

d-i finish-install/reboot_in_progress note
