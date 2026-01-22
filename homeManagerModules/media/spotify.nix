{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.media.spotify;
in
  with lib; {
    options.polaris.homeManager.media.spotify = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Spotify";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [spotify];
    };
  }
