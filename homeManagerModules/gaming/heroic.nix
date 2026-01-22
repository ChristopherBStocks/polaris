{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.gaming.heroic;
in
  with lib; {
    options.polaris.homeManager.gaming.heroic = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Heroic";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [heroic];
    };
  }
