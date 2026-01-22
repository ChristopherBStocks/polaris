{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.media.pinta;
in
  with lib; {
    options.polaris.homeManager.media.pinta = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Pinta";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [pinta];
    };
  }
