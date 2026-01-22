{
  config,
  lib,
  pkgs,
  polarisInputs,
  ...
}: let
  cfg = config.polaris.homeManager.dev.rust;
in
  with lib; {
    options.polaris.homeManager.dev.rust = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Rust";
      };
      additionalExtensions = mkOption {
        type = types.listOf types.str;
        default = [
          "llvm-tools-preview"
        ];
        description = "Rust extensions";
      };
      additionalPackages = mkOption {
        type = types.submodule {
          options = {
            llvmCov = mkOption {
              type = types.bool;
              default = true;
              description = "Enable LLVM Cov";
            };
            nextest = mkOption {
              type = types.bool;
              default = true;
              description = "Enable Nextest";
            };
            tokei = mkOption {
              type = types.bool;
              default = true;
              description = "Enable Tokei";
            };
            sqlxCli = mkOption {
              type = types.bool;
              default = true;
              description = "Enable SQLx CLI";
            };
          };
        };
        default = {};
        description = "Rust Utility Packages";
      };
      credentialProviders = mkOption {
        type = types.listOf types.str;
        default = ["cargo:token" "cargo:libsecret" "cargo:macos-keychain" "cargo:wincred"];
        description = "Cargo credential providers";
      };
      profiles = mkOption {
        type = types.attrsOf types.attrs;
        default = {
          dev = {
            opt-level = 0;
            debug = 2;
            overflow-checks = true;
            incremental = true;
          };

          bench = {
            opt-level = 3;
            debug = true;
            overflow-checks = false;
            incremental = true;
            debug-assertions = false;
            strip = true;
            lto = "fat";
            codegen-units = 1;
          };

          release = {
            opt-level = 3;
            debug = false;
            overflow-checks = true;
            incremental = false;
            strip = true;
            lto = "fat";
            codegen-units = 1;
            panic = "abort";
            rpath = false;
          };

          min-size = {
            inherits = "release";
            opt-level = "z";
          };
        };
        description = "Cargo profiles";
      };
      aliases = mkOption {
        type = types.attrsOf types.str;
        default = {
          b = "build";
          r = "run";
          t = "test";
          rr = "run --release";
          mr = "run --profile min-size";
        };
        description = "Cargo aliases";
      };
    };
    config = mkIf cfg.enable {
      nixpkgs.overlays = [polarisInputs.rustOverlay.overlays.default];
      home.packages = with pkgs;
        [
          rust-analyzer
          (rust-bin.stable.latest.default.override {
            extensions =
              [
                "rust-src"
                "clippy"
                "rustfmt"
              ]
              ++ cfg.additionalExtensions;
          })
          sccache
          mold
          clang
        ]
        ++ optionals cfg.additionalPackages.llvmCov [cargo-llvm-cov]
        ++ optionals cfg.additionalPackages.nextest [cargo-nextest]
        ++ optionals cfg.additionalPackages.tokei [tokei]
        ++ optionals cfg.additionalPackages.sqlxCli [sqlx-cli];
      home.file.".cargo/config.toml".source = (pkgs.formats.toml {}).generate "cargo-config" {
        register = {
          global-credential-providers = cfg.credentialProviders;
        };

        build = {
          rustc-wrapper = "sccache";
          rustflags = ["-C" "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"];
        };

        profile = cfg.profiles;
        alias = cfg.aliases;
      };
    };
  }
