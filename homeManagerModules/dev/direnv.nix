{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.homeManager.dev.direnv;
in
  with lib; {
    options.polaris.homeManager.dev.direnv = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Direnv";
      };
    };
    config = mkIf cfg.enable {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };
  }
