{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.fonts.jetbrainsMono;
in
  with lib; {
    options.polaris.homeManager.fonts.jetbrainsMono = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable JetBrains Mono font";
      };
    };
    config = mkIf cfg.enable {
      fonts.fontconfig.enable = true;
      home.packages = with pkgs; [nerd-fonts.jetbrains-mono];
    };
  }
