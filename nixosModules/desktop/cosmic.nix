{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.desktop.cosmic;
in
  with lib; {
    options.polaris.desktop.cosmic = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Cosmic Environment";
      };
      desktop = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Cosmic desktop environment";
      };
      greeter = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Cosmic greeter";
      };
    };
    config = mkIf cfg.enable (mkMerge [
      (mkIf cfg.desktop {
        services.desktopManager.cosmic.enable = true;
        services.system76-scheduler.enable = true;
      })
      (mkIf cfg.greeter {
        services.displayManager.cosmic-greeter.enable = true;
      })
    ]);
  }
