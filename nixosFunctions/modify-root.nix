{
  lib,
  config,
}: {authorizedKeys ? []}: {
  users.users.root.openssh.authorizedKeys.keys = authorizedKeys;
}
