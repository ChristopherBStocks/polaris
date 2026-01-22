{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.dev.dbeaver;
in
  with lib; {
    options.polaris.homeManager.dev.dbeaver = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable DBeaver";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [dbeaver-bin];
    };
  }
