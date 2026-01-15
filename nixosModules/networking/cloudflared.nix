{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.networking.cloudflared;
in
  with lib; {
    options.polaris.networking.cloudflared = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Cloudflared";
      };
      environmentFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Cloudflared environment file, containing CLOUDFLARED_TOKEN, for connection";
      };
    };
    config = mkIf (cfg.enable && cfg.environmentFile != null) {
      users = {
        users.cloudflared = {
          isSystemUser = true;
          group = "cloudflared";
        };
        groups.cloudflared = {};
      };

      systemd.services.cloudflared = {
        description = "Cloudflare Tunnel";
        wants = ["network-online.target"];
        after = ["network-online.target"];
        wantedBy = ["multi-user.target"];

        serviceConfig = {
          User = "cloudflared";
          Group = "cloudflared";

          EnvironmentFile = cfg.environmentFile;

          ExecStart = ''
            ${pkgs.cloudflared}/bin/cloudflared tunnel run \
              --token "$CLOUDFLARE_TUNNEL_TOKEN"
          '';

          Restart = "always";
          RestartSec = 5;
        };
      };
    };
  }
