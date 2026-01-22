{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.dev.bun;
in
  with lib; {
    options.polaris.homeManager.dev.bun = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Bun";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [bun];
    };
  }
