{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.cli.yubikey;
in
  with lib; {
    options.polaris.homeManager.cli.yubikey = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Yubikey CLI tool";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [yubikey-manager];
    };
  }
