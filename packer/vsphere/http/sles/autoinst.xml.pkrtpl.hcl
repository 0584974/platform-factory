<?xml version="1.0"?>
<!DOCTYPE profile>
<profile xmlns="http://www.suse.com/1.0/yast2ns" xmlns:config="http://www.suse.com/1.0/configns">
  <general>
    <mode>
      <confirm config:type="boolean">false</confirm>
    </mode>
    <signature-handling>
      <accept_unsigned_file config:type="boolean">false</accept_unsigned_file>
      <accept_unknown_gpg_key config:type="boolean">false</accept_unknown_gpg_key>
    </signature-handling>
  </general>
  <language>
    <language>en_US</language>
    <keyboard>english-us</keyboard>
  </language>
  <timezone>
    <hwclock>UTC</hwclock>
    <timezone>UTC</timezone>
  </timezone>
  <networking>
    <keep_install_network config:type="boolean">true</keep_install_network>
  </networking>
  <partitioning config:type="list">
    <drive>
      <device>/dev/sda</device>
      <use>all</use>
    </drive>
  </partitioning>
  <users config:type="list">
    <user>
      <username>${username}</username>
      <fullname>Automation</fullname>
      <user_password>${password_hash}</user_password>
      <encrypted config:type="boolean">true</encrypted>
      <groups>wheel</groups>
    </user>
  </users>
  <software>
    <packages config:type="list">
      <package>openssh</package>
      <package>sudo</package>
      <package>python3</package>
      <package>open-vm-tools</package>
      <package>cloud-init</package>
    </packages>
  </software>
  <scripts>
    <init-scripts config:type="list">
      <script>
        <filename>platform-factory-init.sh</filename>
        <interpreter>shell</interpreter>
        <source><![CDATA[
mkdir -p /etc/sudoers.d
printf '%s\n' '${username} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-${username}
chmod 0440 /etc/sudoers.d/90-${username}
systemctl enable sshd || true
systemctl enable vmtoolsd || true
]]></source>
      </script>
    </init-scripts>
  </scripts>
</profile>
