{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.identity;
in
  with lib; {
    options.polaris.identity = {
      identityPaths = mkOption {
        type = types.listOf types.str;
        default = ["/etc/age/local.key"];
        description = "Age identity paths";
      };
      mutableUsers = mkEnableOption "Mutable users";
      trustedUsers = mkOption {
        type = types.listOf types.str;
        default = ["root"];
        description = "Trusted users";
      };
    };

    config = {
      age.identityPaths = cfg.identityPaths;
      users.mutableUsers = cfg.mutableUsers;
      nix.settings.trusted-users = cfg.trustedUsers;
    };
  }
