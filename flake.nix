{
  description = "A collection of re-usable NixOS modules";

  inputs = {
    # NixOS
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Home-manager 25.11
    hm.url = "github:nix-community/home-manager/release-25.11";
    hm.inputs.nixpkgs.follows = "nixpkgs";

    # rust-overlay
    rustOverlay.url = "github:oxalica/rust-overlay";
    rustOverlay.inputs.nixpkgs.follows = "nixpkgs";

    # Utils
    flakeUtils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flakeUtils,
    rustOverlay,
    ...
  } @ inputs:
    flakeUtils.lib.eachDefaultSystem (system: {
      formatter = nixpkgs.legacyPackages.${system}.alejandra;
    })
    // {
      hardwareModules = (import (self + "/hardwareModules/default.nix")) {
        lib = nixpkgs.lib;
        polarisRoot = self;
      };
      homeManagerModules = (import (self + "/homeManagerModules/default.nix")) {
        lib = nixpkgs.lib;
        polarisRoot = self;
        polarisInputs = inputs;
      };
      nixosFunctions = {
        createUser = import (self + "/nixosFunctions/create-user.nix");
        modifyRoot = import (self + "/nixosFunctions/modify-root.nix");
      };
      nixosModules = (import (self + "/nixosModules/default.nix")) {
        lib = nixpkgs.lib;
        polarisRoot = self;
      };
    };
}
