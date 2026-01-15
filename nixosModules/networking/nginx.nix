{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.networking.nginx;
  genStreamBlock = name: conf: ''
    # Proxy: ${name}
    server {
      listen ${conf.listen};
      proxy_pass ${conf.proxyPass};
    }
  '';
  modsecurityConf = pkgs.writeText "modsecurity.conf" ''
    # --- Base ModSecurity Configuration ---
    SecRuleEngine On
    SecResponseBodyAccess Off
    SecMaxNumArgs 255
    SecReadOnlyState On

    SecUnicodeMapFile ${pkgs.modsecurity-crs}/unicode.mapping 20127

    # --- Audit Logging ---
    SecAuditEngine RelevantOnly
    SecAuditLog /var/log/nginx/modsec_audit.log
    SecAuditLogParts ABIJDEFHKZ
    SecAuditLogType Serial
    SecAuditLogStorageDir /var/lib/modsecurity/audit/
  '';
in
  with lib; {
    options.polaris.networking.nginx = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Nginx";
      };
      streams = mkOption {
        description = "Map of stream proxies (TCP/UDP)";
        default = {};
        type = types.attrsOf (types.submodule {
          options = {
            listen = mkOption {
              type = types.str;
              example = "22";
              description = "Port or IP:Port";
            };
            proxyPass = mkOption {
              type = types.str;
              example = "10.100.0.2:2222";
            };
          };
        });
      };
      hosts = mkOption {
        description = "Map of domains to their specific extra configuration.";
        default = {};
        type = types.attrsOf types.lines;
      };
      acmeEmail = mkOption {
        type = types.str;
        default = "";
        description = "ACME email address";
      };
    };
    config = mkIf cfg.enable {
      environment.systemPackages = [pkgs.modsecurity-crs];
      services.nginx = {
        package = pkgs.nginx.override {
          modules = [
            pkgs.nginxModules.modsecurity
          ];
        };
        enable = true;

        streamConfig = concatStringsSep "\n" (mapAttrsToList genStreamBlock cfg.streams);

        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        sslProtocols = "TLSv1.2 TLSv1.3";
        serverTokens = false;
        clientMaxBodySize = "13107200";

        appendHttpConfig = ''
          client_body_buffer_size 128k;
          modsecurity on;

          # Load ModSecurity Rules
          modsecurity_rules_file ${modsecurityConf};

          # Rate Limiting (10r/s matches 600 events / 1m)
          limit_req_zone $binary_remote_addr zone=per_ip:10m rate=10r/s;

          map $scheme $hsts_header {
            https   "max-age=31536000; includeSubdomains; preload";
          }
          add_header Strict-Transport-Security $hsts_header;
          add_header Content-Security-Policy "script-src 'self'; object-src 'none'; base-uri 'none';" always;
          add_header Permissions-Policy "geolocation=(),midi=(),sync-xhr=(),microphone=(),camera=(self),magnetometer=(),gyroscope=(),fullscreen=(),payment=()";
          add_header Referrer-Policy 'strict-origin-when-cross-origin';
          add_header Cross-Origin-Opener-Policy same-origin;
          add_header Cross-Origin-Resource-Policy same-origin;
          add_header X-XSS-Protection '1; mode=block';
          add_header X-Frame-Options DENY;
          add_header X-Content-Type-Options nosniff;

          proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
        '';

        virtualHosts =
          mapAttrs (domain: extraConfig: {
            enableACME = true;
            forceSSL = true;
            extraConfig = ''
              limit_req zone=per_ip burst=20 nodelay;
              server_tokens off;
              ${extraConfig}
            '';
          })
          cfg.hosts;
      };
      security.acme = {
        acceptTerms = true;
        defaults.email = cfg.acmeEmail;
      };

      networking.firewall.allowedTCPPorts = let
        tcpStreams = filterAttrs (n: v: !(hasInfix "udp" v.listen)) cfg.streams;
        getPort = s: toInt (last (splitString ":" (head (splitString " " s))));
      in
        mapAttrsToList (n: v: getPort v.listen) tcpStreams ++ [80 443];

      networking.firewall.allowedUDPPorts = let
        udpStreams = filterAttrs (n: v: hasInfix "udp" v.listen) cfg.streams;
        getPort = s: toInt (last (splitString ":" (head (splitString " " s))));
      in
        mapAttrsToList (n: v: getPort v.listen) udpStreams;
    };
  }
