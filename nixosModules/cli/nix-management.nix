{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.cli.nixManagement;
in
  with lib; {
    options.polaris.cli.nixManagement = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable nix management cli";
      };
    };
    config = mkIf cfg.enable {
      environment.systemPackages = [pkgs.ragenix pkgs.colmena];
    };
  }
