{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.gaming.prismlauncher;
in
  with lib; {
    options.polaris.homeManager.gaming.prismlauncher = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Prism Launcher";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [prismlauncher];
    };
  }
