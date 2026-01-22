{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.internet.netbird;
in
  with lib; {
    options.polaris.homeManager.internet.netbird = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Netbird";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [netbird netbird-ui];
    };
  }
