{
  description = "A collection of re-usable NixOS modules";

  inputs = {
    # NixOS
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgsUnstable.url = "github:NixOS/nixpkgs/nixos-unstable";

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
    nixpkgsUnstable,
    flakeUtils,
    rustOverlay,
    ...
  } @ inputs: let
    polarisInputs =
      inputs
      // {
        nixpkgsUnstablePkgs = system:
          import nixpkgsUnstable {
            inherit system;
            config.allowUnfree = true;
          };
      };
  in
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
        polarisInputs = polarisInputs;
      };
      nixosFunctions = {
        createUser = import (self + "/nixosFunctions/create-user.nix");
        modifyRoot = import (self + "/nixosFunctions/modify-root.nix");
      };
      nixosModules = (import (self + "/nixosModules/default.nix")) {
        lib = nixpkgs.lib;
        polarisRoot = self;
        polarisInputs = polarisInputs;
      };
    };
}
