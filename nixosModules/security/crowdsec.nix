{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.security.crowdsec;
in
  with lib; {
    options.polaris.security.crowdsec = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable CrowdSec";
      };
      capiFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "CrowdSec CAPI token file";
      };
      lapiFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "CrowdSec LAPI token file";
      };
      acquisitions = mkOption {
        type = types.listOf types.attrs;
        default = [];
        description = "CrowdSec acquisition configuration";
      };
    };
    config = mkIf cfg.enable {
      systemd.services.crowdsec-secrets-setup = {
        description = "Copy CrowdSec secrets";
        requiredBy = ["crowdsec.service"];
        before = ["crowdsec.service"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "copy-crowdsec-secrets" ''
            set -e
            install -d -m 750 -o crowdsec -g crowdsec /var/lib/crowdsec
            ${lib.optionalString (cfg.capiFile != null) "install -D -m 600 -o crowdsec -g crowdsec ${cfg.capiFile} /var/lib/crowdsec/crowdsec-capi.yaml"}
            ${lib.optionalString (cfg.lapiFile != null) "install -D -m 600 -o crowdsec -g crowdsec ${cfg.lapiFile} /var/lib/crowdsec/crowdsec-lapi.yaml"}
          '';
        };
      };
      services.crowdsec = {
        enable = true;
        settings = {
          general.api = {
            server =
              {
                enable = true;
              }
              // lib.optionalAttrs (cfg.capiFile != null) {
                online_client = {
                  credentials_path = "/var/lib/crowdsec/crowdsec-capi.yaml";
                };
              };
            client = lib.optionalAttrs (cfg.lapiFile != null) {
              credentials_path = "/var/lib/crowdsec/crowdsec-lapi.yaml";
            };
          };
        };
      };
    };
  }
