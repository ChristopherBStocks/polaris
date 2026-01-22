{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.gaming.lutris;
in
  with lib; {
    options.polaris.homeManager.gaming.lutris = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Lutris";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [lutris];
    };
  }
