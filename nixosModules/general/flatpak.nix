{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.flatpak;
in
  with lib; {
    options.polaris.flatpak = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Flatpak";
      };
    };
    config = mkIf cfg.enable {
      environment.systemPackages = [pkgs.flatpak];
    };
  }
