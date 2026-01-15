{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.cleanup;
in
  with lib; {
    options.polaris.cleanup = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable garbage collection and store optimisation";
      };
      dates = mkOption {
        type = types.str;
        default = "weekly";
        description = "Garbage collection dates";
      };
      options = mkOption {
        type = types.str;
        default = "--delete-older-than 7d";
        description = "Garbage collection options";
      };
    };
    config = mkIf cfg.enable {
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
      nix.settings.auto-optimise-store = true;
    };
  }
