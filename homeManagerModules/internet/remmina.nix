{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.internet.remmina;
in
  with lib; {
    options.polaris.homeManager.internet.remmina = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Remmina";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [remmina];
    };
  }
