{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.cli.nixUtility;
in
  with lib; {
    options.polaris.cli.nixUtility = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable nix utility cli";
      };
    };
    config = mkIf cfg.enable {
      environment.systemPackages = with pkgs; [nh home-manager git vim wget age];
    };
  }
