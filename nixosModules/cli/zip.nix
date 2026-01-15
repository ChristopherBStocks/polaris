{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.cli.zip;
in
  with lib; {
    options.polaris.cli.zip = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable zip";
      };
    };
    config = mkIf cfg.enable {
      environment.systemPackages = [pkgs.zip pkgs.unzip];
    };
  }
