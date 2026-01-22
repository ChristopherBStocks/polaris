{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.internet.discord;
in
  with lib; {
    options.polaris.homeManager.internet.discord = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Discord client";
      };
      type = mkOption {
        type = types.enum ["discord" "vesktop"];
        default = "vesktop";
        description = "Discord client type";
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        (
          if cfg.type == "discord"
          then discord
          else vesktop
        )
      ];
    };
  }
