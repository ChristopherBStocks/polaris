{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.networking.staticIp;
in
  with lib; {
    options.polaris.networking.staticIp = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Static IP Management";
      };

      interface = mkOption {
        type = types.str;
        description = "The interface to configure with a static IP.";
        example = "enp35s0";
      };

      address = mkOption {
        type = types.str;
        description = "IPv4 address to assign.";
        example = "192.168.1.100";
      };

      prefixLength = mkOption {
        type = types.ints.between 0 32;
        description = "IPv4 prefix length (CIDR).";
        example = 24;
      };

      gateway = mkOption {
        type = types.str;
        description = "IPv4 gateway.";
        example = "192.168.1.1";
      };

      nameservers = mkOption {
        type = types.listOf types.str;
        default = ["1.1.1.3" "1.0.0.3"];
        description = "IPv4 nameservers.";
        example = ["1.1.1.3" "1.0.0.3"];
      };
    };

    config = mkIf cfg.enable {
      networking = {
        useDHCP = lib.mkForce false;
        nameservers = cfg.nameservers;
        defaultGateway = cfg.gateway;
        interfaces = {
          ${cfg.interface} = {
            ipv4.addresses = [
              {
                address = cfg.address;
                prefixLength = cfg.prefixLength;
              }
            ];
          };
        };
      };
    };
  }
