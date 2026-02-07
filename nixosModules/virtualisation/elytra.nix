{
  config,
  lib,
  pkgs,
  ...
}: let
  elytra-bin = pkgs.stdenv.mkDerivation {
    pname = "elytra";
    version = "latest";

    src = pkgs.fetchurl {
      url = "https://github.com/pyrohost/elytra/releases/download/v1.3.0/elytra_linux_amd64";
      sha256 = "b23489e54828e5645282aee2d422e85060bba55edc2f802e967ebbe081f741cc";
    };

    phases = ["installPhase"];
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/elytra
      chmod +x $out/bin/elytra
    '';
  };
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
