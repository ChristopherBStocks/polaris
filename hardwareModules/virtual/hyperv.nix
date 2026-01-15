{lib, ...}: {
  boot = {
    initrd = {
      availableKernelModules = ["sd_mod" "sr_mod" "tpm_crb" "tpm_tis" "tpm_tis_core"];
      systemd.tpm2.enable = true;
    };
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  virtualisation.hypervGuest.enable = true;
}
