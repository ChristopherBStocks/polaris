{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.gaming.steam;
in
  with lib; {
    options.polaris.gaming.steam = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Steam";
      };
      remotePlayFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Open firewall for Steam Remote Play";
      };
      dedicatedServerFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Open firewall for Steam Dedicated Server";
      };
      localNetworkGameTransfersFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Open firewall for Steam Local Network Game Transfers";
      };
    };
    config = mkIf cfg.enable {
      nixpkgs.config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "steam"
          "steam-original"
          "steam-unwrapped"
          "steam-run"
        ];
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = cfg.remotePlayFirewall;
        dedicatedServer.openFirewall = cfg.dedicatedServerFirewall;
        localNetworkGameTransfers.openFirewall = cfg.localNetworkGameTransfersFirewall;
      };
    };
  }
