{
  description = "A collection of re-usable NixOS modules";

  inputs = {
    # NixOS
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # CrowdSec

    # Utils
    flakeUtils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flakeUtils,
    ...
  } @ inputs:
    flakeUtils.lib.eachDefaultSystem (system: {
      formatter = nixpkgs.legacyPackages.${system}.alejandra;
    })
    // {
      nixosFunctions = {
        createUser = import (self + "/nixosFunctions/create-user.nix");
        modifyRoot = import (self + "/nixosFunctions/modify-root.nix");
      };
      nixosModules = (import (self + "/nixosModules/default.nix")) {
        lib = nixpkgs.lib;
        polarisRoot = self;
      };
      hardwareModules = (import (self + "/hardwareModules/default.nix")) {
        lib = nixpkgs.lib;
        polarisRoot = self;
      };
    };
}
