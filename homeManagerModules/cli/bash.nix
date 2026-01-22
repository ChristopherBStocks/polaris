{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.homeManager.cli.bash;
in
  with lib; {
    options.polaris.homeManager.cli.bash = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Bash shell integration";
      };
    };
    config = mkIf cfg.enable {
      programs.bash = {
        enable = true;
      };
    };
  }
