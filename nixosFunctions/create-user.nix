{
  lib,
  config,
}: {
  username,
  description,
  groups ? [],
  authorizedKeys ? [],
  passwordFile ? null,
  passwordLessSudo ? false,
}: let
  hasPassword = passwordFile != null;
  secretName = "${username}-password";
in {
  age.secrets = lib.mkIf hasPassword {
    "${secretName}".file = passwordFile;
  };
  users.users."${username}" = {
    isNormalUser = true;
    description = description;
    extraGroups = groups;
    openssh.authorizedKeys.keys = authorizedKeys;
    hashedPasswordFile =
      if hasPassword
      then config.age.secrets."${secretName}".path
      else null;
  };
  security.sudo.extraRules = lib.mkIf passwordLessSudo [
    {
      users = [username];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
