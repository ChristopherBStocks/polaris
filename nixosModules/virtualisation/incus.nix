{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.virtualisation.incus;
in
  with lib; {
    options.polaris.virtualisation.incus = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Incus";
      };
      externalInterface = mkOption {
        type = types.str;
        description = "The external interface to bind Incus to.";
        example = "wt-wan";
      };
      externalTcpPortRanges = mkOption {
        type = types.listOf (types.attrsOf types.int);
        default = [];
        description = "TCP port ranges (e.g. [{ from = 1; to = 65535; }])";
      };
      externalUdpPortRanges = mkOption {
        type = types.listOf (types.attrsOf types.int);
        default = [];
        description = "UDP port ranges (e.g. [{ from = 1; to = 65535; }])";
      };
      externalTcpPorts = mkOption {
        type = types.listOf types.int;
        description = "TCP ports to allow through the firewall.";
        default = [];
      };
      externalUdpPorts = mkOption {
        type = types.listOf types.int;
        description = "UDP ports to allow through the firewall.";
        default = [];
      };
      enableUi = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Incus UI.";
      };
      uiInterface = mkOption {
        type = types.str;
        description = "The external interface to bind the Incus UI to.";
        example = "wt-wan";
      };
      extraForwardRules = mkOption {
        type = types.str;
        default = "";
        description = "Extra firewall rules for Incus.";
      };
    };

    config = mkIf cfg.enable {
      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
      networking = {
        nftables.enable = true;
        firewall = {
          extraForwardRules = cfg.extraForwardRules;
          interfaces =
            {
              "${cfg.externalInterface}" = {
                allowedTCPPorts =
                  cfg.externalTcpPorts
                  ++ (optionals (cfg.uiInterface == cfg.externalInterface && cfg.enableUi) [8443]);
                allowedUDPPorts = cfg.externalUdpPorts;
                allowedTCPPortRanges = cfg.externalTcpPortRanges;
                allowedUDPPortRanges = cfg.externalUdpPortRanges;
              };
            }
            // optionalAttrs (cfg.uiInterface != cfg.externalInterface && cfg.enableUi) {
              "${cfg.uiInterface}" = {
                allowedTCPPorts = [8443];
              };
            }
            // {
              "incusbr0" = {
                allowedTCPPorts = [53 139 339 445];
                allowedUDPPorts = [53 67 339];
              };
            };
        };
      };
      virtualisation.incus = {
        enable = true;
        ui.enable = cfg.enableUi;
      };
    };
  }
