{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.dev.just;
in
  with lib; {
    options.polaris.homeManager.dev.just = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Just";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [just];
    };
  }
