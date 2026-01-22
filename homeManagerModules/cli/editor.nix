{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.homeManager.cli.editor;
in
  with lib; {
    options.polaris.homeManager.cli.editor = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Set specified editor as default";
      };
      type = mkOption {
        type = types.enum ["vim" "nvim"];
        default = "vim";
        description = "Editor type";
      };
    };
    config = mkIf cfg.enable {
      home.sessionVariables = {
        EDITOR = cfg.type;
        VISUAL = cfg.type;
      };
    };
  }
