{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.dev.opencode;
in
  with lib; {
    options.polaris.homeManager.dev.opencode = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable OpenCode";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [opencode];
    };
  }
