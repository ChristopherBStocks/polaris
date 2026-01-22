{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.homeManager.dev.git;
in
  with lib; {
    options.polaris.homeManager.dev.git = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Git";
      };
      editor = mkOption {
        type = types.str;
        default = "vim";
        description = "Git editor";
      };
      defaultBranch = mkOption {
        type = types.str;
        default = "main";
        description = "Git default branch";
      };
      signing = mkOption {
        type = types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Enable Git signing";
            };
            key = mkOption {
              type = types.str;
              default = "${config.home.homeDirectory}/.ssh/id_ed25519";
              description = "Git signing key";
            };
            format = mkOption {
              type = types.enum ["pgp" "ssh"];
              default = "ssh";
              description = "Git signing format";
            };
            allowedSignersFile = mkOption {
              type = types.str;
              default = "${config.home.homeDirectory}/.ssh/allowed_signers";
              description = "Git allowed signers file";
            };
            allowedSigners = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Git allowed signers";
            };
          };
        };
        default = {};
        description = "Git signing configuration";
      };
    };
    config = mkIf cfg.enable (mkMerge [
      {
        programs.git = {
          enable = true;
          settings = {
            core.editor = cfg.editor;
            init.defaultBranch = cfg.defaultBranch;
            push.autoSetupRemote = true;
            pull.rebase = true;
            core.whitespace = "fix,space-before-tab,trailing-space,empty-lines";
          };
        };
        programs.delta = {
          enable = true;
          options = {
            navigate = true;
            light = false;
            side-by-side = true;
          };
        };
      }
      (mkIf cfg.signing.enable {
        programs.git = {
          signing = {
            signByDefault = true;
            key = cfg.signing.key;
          };
          settings = {
            commit.gpgSign = true;
            tag.gpgSign = true;
            format.signOff = true;
            gpg = {
              format = cfg.signing.format;
              ssh = {
                allowedSignersFile = cfg.signing.allowedSignersFile;
              };
            };
          };
        };
        home.file."${cfg.signing.allowedSignersFile}".text =
          lib.concatStringsSep "\n" cfg.signing.allowedSigners;
      })
    ]);
  }
