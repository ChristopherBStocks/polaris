{
  config,
  lib,
  pkgs,
  polarisInputs,
  ...
}: let
  cfg = config.polaris.homeManager.dev.kreya;
  unstable = polarisInputs.nixpkgsUnstablePkgs pkgs.system;
in
  with lib; {
    options.polaris.homeManager.dev.kreya = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Kreya";
      };
    };
    config = mkIf cfg.enable {
      home.packages = [unstable.kreya];
    };
  }
