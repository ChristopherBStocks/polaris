{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.system.missionCenter;
in
  with lib; {
    options.polaris.homeManager.system.missionCenter = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Mission Center";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [mission-center];
    };
  }
