{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.dev.prettier;
in
  with lib; {
    options.polaris.homeManager.dev.prettier = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Prettier";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [prettier];
    };
  }
