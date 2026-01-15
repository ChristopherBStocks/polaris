{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.networking.iptableForwarding;

  generateIptables = rangeConfiguration: let
    targetIP = rangeConfiguration.targetIP;
    protocol = rangeConfiguration.protocol;
    portSpec = rangeConfiguration.portRange;
  in ''
    iptables -t nat -A PREROUTING -p ${protocol} --dport ${portSpec} -j DNAT --to-destination ${targetIP}
    iptables -A FORWARD -p ${protocol} -d ${targetIP} --dport ${portSpec} -j ACCEPT
    iptables -t nat -A POSTROUTING -d ${targetIP} -p ${protocol} --dport ${portSpec} -j MASQUERADE
  '';
in
  with lib; {
    options.polaris.networking.iptableForwarding = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable iptable forwarding";
      };

      ranges = mkOption {
        description = "List of port forwarding ranges.";
        default = [];
        type = types.listOf (types.submodule {
          options = {
            portRange = mkOption {
              type = types.str;
              example = "25500:25600";
            };
            targetIP = mkOption {
              type = types.str;
              example = "10.100.0.2";
            };
            protocol = mkOption {
              type = types.enum ["tcp" "udp"];
              default = "tcp";
            };
          };
        });
      };
    };

    config = mkIf (cfg.enable && cfg.ranges != []) {
      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
      networking.firewall.extraCommands = concatMapStringsSep "\n" generateIptables cfg.ranges;
      networking.firewall.extraStopCommands = ''
        iptables -t nat -F PREROUTING
        iptables -F FORWARD
        iptables -t nat -F POSTROUTING
      '';
    };
  }
