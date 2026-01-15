{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.virtualisation.docker;
in
  with lib; {
    options.polaris.virtualisation.docker = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Docker";
      };

      enableOnBoot = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Docker on boot - required for restart=always";
      };

      users = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of users to add to the docker group";
      };

      dataRoot = mkOption {
        type = types.str;
        default = "/var/lib/docker";
        description = "Docker data root";
      };

      liveRestore = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Docker live restore";
      };

      rootless = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Docker rootless";
      };

      logMaxSize = mkOption {
        type = types.str;
        default = "10m";
        description = "Docker log max size";
      };

      logMaxFiles = mkOption {
        type = types.int;
        default = 3;
        description = "Docker log max files";
      };
    };
    config = mkIf cfg.enable (mkMerge [
      {
        virtualisation.docker = {
          enable = true;
          logDriver = "json-file";
          liveRestore = cfg.liveRestore;
          enableOnBoot = cfg.enableOnBoot;
          daemon.settings = {
            userland-proxy = false;
            icc = false;
            no-new-privileges = true;
            log-level = "info";
            data-root = cfg.dataRoot;
            log-opts = {
              max-size = cfg.logMaxSize;
              max-file = toString cfg.logMaxFiles;
            };
          };
        };
        users.extraGroups.docker.members = cfg.users;
      }
      (mkIf cfg.rootless {
        virtualisation.docker.rootless = {
          enable = true;
          setSocketVariable = true;
        };
      })
    ]);
  }
