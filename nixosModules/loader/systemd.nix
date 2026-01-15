{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.systemd;
in
  with lib; {
    options.polaris.systemd = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Systemd";
      };
    };
    config = mkIf cfg.enable {
      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
    };
  }
