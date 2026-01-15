{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.localisation;
in
  with lib; {
    options.polaris.localisation = {
      timeZone = mkOption {
        type = types.str;
        default = "Europe/London";
        description = "Time zone";
      };
      defaultLocale = mkOption {
        type = types.str;
        default = "en_GB.UTF-8";
        description = "Default locale";
      };
      keyboardLayout = mkOption {
        type = types.str;
        default = "us";
        description = "Keyboard layout";
      };
      keymap = mkOption {
        type = types.str;
        default = "uk";
        description = "Keyboard keymap";
      };
    };

    config = {
      time.timeZone = cfg.timeZone;
      i18n = {
        defaultLocale = cfg.defaultLocale;
        extraLocaleSettings = {
          LC_ALL = cfg.defaultLocale;
        };
      };
      services.xserver.xkb.layout = cfg.keyboardLayout;
      console.keyMap = cfg.keymap;
    };
  }
