{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.networking;
in
  with lib; {
    options.polaris.networking = {
      enableFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Enable firewall";
      };
    };
    config = {
      services.resolved.enable = true;
      networking = {
        firewall.enable = cfg.enableFirewall;
        networkmanager = {
          enable = true;
          dns = "systemd-resolved";
        };
      };
    };
  }
