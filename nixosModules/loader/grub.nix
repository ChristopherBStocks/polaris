{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.grub;
in
  with lib; {
    options.polaris.grub = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Grub";
      };
      devices = mkOption {
        type = types.listOf types.str;
        default = ["/dev/sda"];
        description = "Grub devices";
      };
    };
    config = mkIf cfg.enable {
      boot.loader.grub = {
        enable = true;
        devices = mkOverride 90 cfg.devices;
      };
    };
  }
