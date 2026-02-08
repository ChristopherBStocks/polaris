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
    inIf         = rangeConfiguration.inInterface;
    outIf        = rangeConfiguration.outInterface;
  in ''
    iptables -t nat -A POLARIS_PREROUTING -i ${inIf} -p ${protocol} --dport ${portSpec} \
      -j DNAT --to-destination ${targetIP}
    iptables -A POLARIS_FORWARD -i ${inIf} -o ${outIf} -p ${protocol} -d ${targetIP} --dport ${portSpec} -j ACCEPT
    iptables -A POLARIS_FORWARD -i ${outIf} -o ${inIf} -p ${protocol} -s ${targetIP} --sport ${portSpec} -j ACCEPT
    iptables -t nat -A POLARIS_POSTROUTING -o ${outIf} -p ${protocol} -d ${targetIP} --dport ${portSpec} -j MASQUERADE
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
            inInterface = mkOption {
                        type = types.str;
                        example = "ens3";
                        description = "Ingress interface (public/WAN).";
                      };

                      outInterface = mkOption {
                        type = types.str;
                        example = "wt-wan";
                        description = "Egress interface toward the target (e.g. NetBird).";
                      };
          };
        });
      };
    };

    config = mkIf (cfg.enable && cfg.ranges != []) {
        boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
        networking.firewall.enable = true;
        networking.firewall.extraCommands = ''
          iptables -t nat -N POLARIS_PREROUTING 2>/dev/null || true
          iptables -t nat -N POLARIS_POSTROUTING 2>/dev/null || true
          iptables -N POLARIS_FORWARD 2>/dev/null || true

          iptables -t nat -F POLARIS_PREROUTING
          iptables -t nat -F POLARIS_POSTROUTING
          iptables -F POLARIS_FORWARD

          iptables -t nat -C PREROUTING -j POLARIS_PREROUTING 2>/dev/null || iptables -t nat -A PREROUTING -j POLARIS_PREROUTING
          iptables -t nat -C POSTROUTING -j POLARIS_POSTROUTING 2>/dev/null || iptables -t nat -A POSTROUTING -j POLARIS_POSTROUTING
          iptables -C FORWARD -j POLARIS_FORWARD 2>/dev/null || iptables -A FORWARD -j POLARIS_FORWARD

          ${concatMapStringsSep "\n" generateIptables cfg.ranges}
        '';

        networking.firewall.extraStopCommands = ''
          iptables -t nat -D PREROUTING -j POLARIS_PREROUTING 2>/dev/null || true
          iptables -t nat -D POSTROUTING -j POLARIS_POSTROUTING 2>/dev/null || true
          iptables -D FORWARD -j POLARIS_FORWARD 2>/dev/null || true

          iptables -t nat -F POLARIS_PREROUTING 2>/dev/null || true
          iptables -t nat -F POLARIS_POSTROUTING 2>/dev/null || true
          iptables -F POLARIS_FORWARD 2>/dev/null || true

          iptables -t nat -X POLARIS_PREROUTING 2>/dev/null || true
          iptables -t nat -X POLARIS_POSTROUTING 2>/dev/null || true
          iptables -X POLARIS_FORWARD 2>/dev/null || true
        '';
      };
  }
