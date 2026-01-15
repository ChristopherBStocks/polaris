{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.security.fail2ban;
in
  with lib; {
    options.polaris.security.fail2ban = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Fail2Ban";
      };
      maxRetry = mkOption {
        type = types.int;
        default = 3;
        description = "Fail2Ban max retry";
      };

      banTime = mkOption {
        type = types.str;
        default = "24h";
        description = "Fail2Ban ban time";
      };

      findTime = mkOption {
        type = types.str;
        default = "30m";
        description = "Fail2Ban find time";
      };

      sshPorts = mkOption {
        type = types.listOf types.int;
        default = [22];
        description = "Fail2Ban SSH ports";
      };

      banTimeMultiplier = mkOption {
        type = types.str;
        default = "1 2 4 8 16 32 64";
        description = "Fail2Ban ban time multiplier";
      };

      banTimeMaxTime = mkOption {
        type = types.str;
        default = "168h";
        description = "Fail2Ban ban time max time";
      };

      ignoreIP = mkOption {
        type = types.listOf types.str;
        default = ["127.0.0.1/8" "::1"];
        description = "Fail2Ban ignore IP";
      };

      extraJails = mkOption {
        type = types.attrs;
        default = {};
        description = "Fail2Ban extra jails";
      };
    };
    config = mkIf cfg.enable {
      networking.firewall.enable = mkDefault true;
      services.fail2ban = {
        enable = true;
        maxretry = cfg.maxRetry;
        bantime = cfg.banTime;
        ignoreIP = cfg.ignoreIP;
        bantime-increment = {
          enable = true;
          multipliers = cfg.banTimeMultiplier;
          maxtime = cfg.banTimeMaxTime;
          overalljails = true;
        };

        jails =
          {
            sshd.settings = {
              enabled = config.services.openssh.enable;
              backend = "systemd";
              port = concatMapStringsSep "," toString cfg.sshPorts;
              mode = "aggressive";
              maxretry = cfg.maxRetry;
              findtime = cfg.findTime;
              bantime = cfg.banTime;
            };
          }
          // cfg.extraJails;
      };
    };
  }
