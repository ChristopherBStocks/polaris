{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.virtualisation.elytra;
in
  with lib; {
    options.polaris.virtualisation.elytra = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Elytra";
      };
    };
    config = mkIf cfg.enable {
      networking.firewall.trustedInterfaces = ["docker0"];
      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv4.conf.all.forwarding" = true;
      };

      users.groups.pyrodactyl = {};
      users.users.pyrodactyl = {
        isSystemUser = true;
        group = "pyrodactyl";
        extraGroups = ["docker"];
        home = "/var/lib/elytra";
        createHome = true;
      };

      environment.systemPackages = [
        elytra-bin
        pkgs.rustic
        pkgs.shadow
        pkgs.gzip
      ];

      systemd.services.elytra = {
        description = "Elytra - Pyro Game Server Daemon";
        after = ["network.target" "docker.service"];
        requires = ["docker.service"];
        wantedBy = ["multi-user.target"];

        path = with pkgs; [
          rustic
          shadow
          gzip
        ];

        serviceConfig = {
          ExecStart = "${elytra-bin}/bin/elytra";
          User = "root";
          WorkingDirectory = "/var/lib/elytra";
          Restart = "always";
        };
        preStart = ''
          mkdir -p /var/lib/elytra
        '';
      };
    };
  }
