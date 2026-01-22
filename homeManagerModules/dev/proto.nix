{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.dev.proto;
in
  with lib; {
    options.polaris.homeManager.dev.proto = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Proto";
      };
      languageModules = mkOption {
        type = types.submodule {
          options = {
            java = mkOption {
              type = types.bool;
              default = false;
              description = "Enable Java language module";
            };
          };
        };
      };
    };
    config = mkIf cfg.enable {
      home.packages = with pkgs;
        [
          protobuf
        ]
        ++ optionals cfg.languageModules.java [
          protoc-gen-grpc-java
        ];
    };
  }
