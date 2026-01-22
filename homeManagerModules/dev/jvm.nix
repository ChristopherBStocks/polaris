{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.homeManager.dev.jvm;
  hasProtobuf = lib.any (p: lib.getName p == "protobuf") config.home.packages;
in
  with lib; {
    options.polaris.homeManager.dev.jvm = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable JVM";
      };
      jdk = mkOption {
        type = types.package;
        default = pkgs.openjdk25;
        description = "JVM JDK";
      };
      enableKotlin = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Kotlin";
      };
      buildTools = mkOption {
        type = types.submodule {
          options = {
            maven = mkOption {
              type = types.bool;
              default = true;
              description = "Enable Maven";
            };
            gradle = mkOption {
              type = types.bool;
              default = true;
              description = "Enable Gradle";
            };
          };
        };
        default = {};
        description = "JVM build tools";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        programs.java = {
          enable = true;
          package = cfg.jdk;
        };

        home.sessionVariables = {
          JAVA_HOME = "${cfg.jdk}/lib/openjdk";
        };

        home = {
          file.".gradle/gradle.properties".text =
            ''
              org.gradle.java.installations.paths=${cfg.jdk}/lib/openjdk
            ''
            + lib.optionalString hasProtobuf ''
              protoc.path=${pkgs.protobuf}/bin/protoc
              grpc.plugin.path=${pkgs.protoc-gen-grpc-java}/bin/protoc-gen-grpc-java
            '';
        };
      }
      (mkIf cfg.enableKotlin {
        home.packages = with pkgs; [kotlin ktfmt];
      })
      (mkIf cfg.buildTools.maven {
        home.packages = with pkgs; [maven];
      })
      (mkIf cfg.buildTools.gradle {
        home.packages = with pkgs; [gradle];
      })
    ]);
  }
