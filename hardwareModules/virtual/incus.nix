{modulesPath, ...}: {
  imports = [
    "${modulesPath}/virtualisation/incus-virtual-machine.nix"
  ];

  networking = {
    dhcpcd.enable = false;
    useDHCP = false;
    useHostResolvConf = false;
  };
}
