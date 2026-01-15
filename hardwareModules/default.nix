{
  lib,
  polarisRoot,
  ...
}: let
  collectModules = dir: prefix: let
    entries = builtins.readDir dir;
  in
    lib.foldl' (
      acc: name: let
        path = "${dir}/${name}";
        type = entries.${name};
      in
        if type == "directory"
        then
          acc
          // (collectModules path (
            if prefix == ""
            then name
            else "${prefix}-${name}"
          ))
        else if lib.hasSuffix ".nix" name && name != "default.nix"
        then let
          key =
            if prefix == ""
            then lib.removeSuffix ".nix" name
            else "${prefix}-${lib.removeSuffix ".nix" name}";
        in
          acc // {"${key}" = path;}
        else acc
    ) {} (builtins.attrNames entries);
in
  collectModules (polarisRoot + "/hardwareModules") ""
