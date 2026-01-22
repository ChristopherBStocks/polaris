{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.dev.idea;
in
  with lib; {
    options.polaris.homeManager.dev.idea = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable IntelliJ IDEA";
      };
      overlay = mkOption {
        type = types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Enable IntelliJ IDEA overlay";
            };
            java = mkOption {
              type = types.package;
              default = pkgs.openjdk25;
              description = "IntelliJ IDEA Java";
            };
            version = mkOption {
              type = types.str;
              default = "2025.3.1.1";
              description = "IntelliJ IDEA version";
            };
            url = mkOption {
              type = types.str;
              default = "https://download-cdn.jetbrains.com/idea/idea-${cfg.overlay.version}.tar.gz";
              description = "IntelliJ IDEA URL";
            };
            hash = mkOption {
              type = types.str;
              default = "OgZLIpYfPzm4ZrZLYoVY4ND3CNQjo/lWXUPw6BGWmXs=";
              description = "IntelliJ IDEA hash";
            };
          };
        };
        default = {};
        description = "IntelliJ IDEA overlay configuration";
      };
    };
    config = mkIf cfg.enable {
      nixpkgs.overlays = [
        (final: prev: {
          jetbrains =
            prev.jetbrains
            // {
              idea =
                (prev.jetbrains.idea.override {
                  jdk = cfg.overlay.java;
                }).overrideAttrs (oldAttrs: rec {
                  version = cfg.overlay.version;
                  src = prev.fetchurl {
                    url = cfg.overlay.url;
                    sha256 = cfg.overlay.hash;
                  };
                });
            };
        })
      ];
      home.packages = with pkgs; [jetbrains.idea];
    };
  }
