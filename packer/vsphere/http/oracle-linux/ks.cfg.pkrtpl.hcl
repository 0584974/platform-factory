text
cdrom
lang en_US.UTF-8
keyboard us
timezone UTC --utc
network --bootproto=dhcp --device=link --activate
rootpw --lock
user --name=${username} --password=${password_hash} --iscrypted --groups=wheel
firewall --enabled --service=ssh
selinux --enforcing
bootloader --location=mbr
autopart --type=lvm
clearpart --all --initlabel
reboot

%packages
@^minimal-environment
openssh-server
sudo
python3
open-vm-tools
cloud-init
%end

%post --log=/root/ks-post.log
cat > /etc/sudoers.d/90-${username} <<'EOF'
${username} ALL=(ALL) NOPASSWD:ALL
EOF
chmod 0440 /etc/sudoers.d/90-${username}
systemctl enable sshd
systemctl enable vmtoolsd || true
%end
