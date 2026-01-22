{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.cli.tree;
in
  with lib; {
    options.polaris.homeManager.cli.tree = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable tree command";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [tree];
    };
  }
