{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.networking.netbird;
in
  with lib; {
    options.polaris.networking.netbird = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Netbird";
      };
      environmentFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Netbird environment file, containing NETBIRD_SETUP_KEY, for auto connection";
      };
      port = mkOption {
        type = types.int;
        default = 51820;
        description = "Netbird port";
      };
      interface = mkOption {
        type = types.str;
        default = "wt-wan";
        description = "Netbird interface";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        services.netbird = {
          enable = true;
          clients.wan = {
            port = cfg.port;
            interface = cfg.interface;
          };
        };
      }
      (mkIf (cfg.environmentFile != null) {
        systemd.services."netbird-wan-up" = {
          description = "Initial NetBird login for wan client";
          after = ["network-online.target" "netbird-wan.service"];
          wants = ["network-online.target"];
          wantedBy = ["multi-user.target"];

          serviceConfig = {
            Type = "oneshot";
            EnvironmentFile = cfg.environmentFile;
          };

          script = ''
            set -eu
            /run/current-system/sw/bin/netbird-wan up \
              --setup-key "$NETBIRD_SETUP_KEY"
          '';
        };
      })
    ]);
  }
