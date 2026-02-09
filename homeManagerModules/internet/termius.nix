{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.internet.termius;
in
  with lib; {
    options.polaris.homeManager.internet.termius = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Termius";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [termius];
    };
  }
