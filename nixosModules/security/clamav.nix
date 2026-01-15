{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.security.clamav;
in
  with lib; {
    options.polaris.security.clamav = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable ClamAV";
      };

      quarantineLocation = mkOption {
        type = types.str;
        default = "/var/lib/clamav/quarantine";
        description = "ClamAV quarantine location";
      };

      scanDirectories = mkOption {
        type = types.listOf types.str;
        default = ["/home" "/var/lib" "/tmp" "/etc" "/var/tmp"];
        description = "ClamAV scan directories";
      };
    };
    config = mkIf cfg.enable {
      systemd.tmpfiles.rules = ["d ${cfg.quarantineLocation} 0750 clamav clamav -"];
      services.clamav = {
        daemon.enable = true;
        updater.enable = true;
        scanner = {
          enable = true;
          scanDirectories = cfg.scanDirectories;
        };
      };
    };
  }
