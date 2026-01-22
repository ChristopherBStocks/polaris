{
  lib,
  polarisRoot,
  polarisInputs,
  ...
}: let
  discoverAbsoluteModulePaths = dir:
    lib.flatten (lib.mapAttrsToList (
      name: type: let
        absolutePath = "${dir}/${name}";
      in
        if type == "directory"
        then discoverAbsoluteModulePaths absolutePath
        else if lib.hasSuffix ".nix" name && name != "default.nix"
        then [absolutePath]
        else []
    ) (builtins.readDir dir));
  allPolarisModulePaths = discoverAbsoluteModulePaths (polarisRoot + "/homeManagerModules");
in {
  imports = allPolarisModulePaths;
  _module.args = {inherit polarisInputs;};
}
