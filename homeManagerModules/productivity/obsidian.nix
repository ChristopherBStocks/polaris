{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.productivity.obsidian;
in
  with lib; {
    options.polaris.homeManager.productivity.obsidian = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Obsidian";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [obsidian];
    };
  }
