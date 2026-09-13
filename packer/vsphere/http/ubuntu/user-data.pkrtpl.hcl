#cloud-config
autoinstall:
  version: 1
  locale: en_US.UTF-8
  keyboard:
    layout: us
  identity:
    hostname: packer-ubuntu
    username: ${username}
    password: '${password_hash}'
  ssh:
    install-server: true
    allow-pw: true
  storage:
    layout:
      name: direct
  packages:
    - open-vm-tools
    - cloud-init
    - python3
    - sudo
  late-commands:
    - curtin in-target --target=/target -- sh -c "echo '${username} ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/90-${username}"
    - curtin in-target --target=/target -- chmod 440 /etc/sudoers.d/90-${username}
