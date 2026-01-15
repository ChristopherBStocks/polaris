{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.networking.openssh;
in
  with lib; {
    options.polaris.networking.openssh = {
      enable = mkEnableOption "Enable OpenSSH Server";
      ports = mkOption {
        type = types.listOf types.int;
        default = [22];
        description = "OpenSSH Server ports";
      };

      permitRootLogin = mkOption {
        type = types.enum ["yes" "no" "prohibit-password"];
        default = "prohibit-password";
        description = "OpenSSH Server permit root login";
      };

      maxAuthTries = mkOption {
        type = types.int;
        default = 3;
        description = "OpenSSH Server max auth tries";
      };

      loginGraceTime = mkOption {
        type = types.str;
        default = "30s";
        description = "OpenSSH Server login grace time";
      };

      clientAliveCountMax = mkOption {
        type = types.int;
        default = 3;
        description = "OpenSSH Server client alive count max";
      };

      clientAliveInterval = mkOption {
        type = types.str;
        default = "60s";
        description = "OpenSSH Server client alive interval";
      };

      maxSessions = mkOption {
        type = types.int;
        default = 5;
        description = "OpenSSH Server max sessions";
      };

      allowedUsers = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "OpenSSH Server allowed users";
      };

      allowedGroups = mkOption {
        type = types.listOf types.str;
        default = ["root" "wheel"];
        description = "OpenSSH Server allowed groups";
      };

      maxStartups = mkOption {
        type = types.str;
        default = "10:30:60";
        description = "OpenSSH Server max startups";
      };

      allowTcpForwarding = mkOption {
        type = types.bool;
        default = false;
        description = "Allow TCP forwarding";
      };

      allowAgentForwarding = mkOption {
        type = types.bool;
        default = false;
        description = "Allow agent forwarding";
      };
    };
    config = mkIf cfg.enable {
      services.openssh = {
        enable = true;
        ports = cfg.ports;
        settings = {
          PermitRootLogin = cfg.permitRootLogin;
          MaxAuthTries = cfg.maxAuthTries;
          LoginGraceTime = cfg.loginGraceTime;
          ClientAliveCountMax = cfg.clientAliveCountMax;
          ClientAliveInterval = cfg.clientAliveInterval;
          MaxStartups = cfg.maxStartups;
          MaxSessions = cfg.maxSessions;
          AllowGroups = cfg.allowedGroups;
          AllowUsers =
            if cfg.allowedUsers == []
            then null
            else cfg.allowedUsers;
          PasswordAuthentication = false;
          PubkeyAuthentication = true;
          PermitEmptyPasswords = false;
          ChallengeResponseAuthentication = false;
          AllowAgentForwarding = cfg.allowAgentForwarding;
          AllowTcpForwarding = cfg.allowTcpForwarding;
          X11Forwarding = false;
          IgnoreRhosts = true;
          HostBasedAuthentication = false;
          UseDns = false;
          LogLevel = "VERBOSE";
        };
        openFirewall = false;
      };
      networking.firewall.allowedTCPPorts = cfg.ports;
    };
  }
