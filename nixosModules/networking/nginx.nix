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
  crsRulesFile =
    pkgs.runCommand "crs-rules-include.conf" {
      nativeBuildInputs = [pkgs.findutils pkgs.coreutils];
    } ''
      # Dynamically find the 'rules' directory inside the package
      RULES_DIR=$(find ${pkgs.modsecurity-crs} -type d -name "rules" -print -quit)

      if [ -z "$RULES_DIR" ]; then
        echo "ERROR: Could not find 'rules' directory in ${pkgs.modsecurity-crs}"
        exit 1
      fi

      # Write sorted includes to output
      for file in $(ls $RULES_DIR/*.conf | sort); do
        echo "Include $file" >> $out
      done
    '';
  modsecurityConf = pkgs.writeText "modsecurity.conf" ''
     ## Base Engine

     # Enables Rule Sets
     SecRuleEngine On
     # Allows seeing request body
     SecRequestBodyAccess On
     # Allows seeing response body
     SecResponseBodyAccess On
     # Telemetry
     SecStatusEngine Off

     # Enables XML processing
     SecRule REQUEST_HEADERS:Content-Type "^(?:application(?:/soap\+|/)|text/)xml" \
          "id:'200000',phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=XML"

     # Enables JSON processing
     SecRule REQUEST_HEADERS:Content-Type "^application/json" \
          "id:'200001',phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=JSON"

    # Maximum request body size (file upload)
    SecRequestBodyLimit 134217728
    # Maximum request body size (excluding file upload)
    SecRequestBodyNoFilesLimit 1048576

     # Reject requests with oversized bodies
     SecRequestBodyLimitAction Reject

    # Maximum JSON depth
    SecRequestBodyJsonDepthLimit 512

    # Maximum arguments
    SecArgumentsLimit 1000

    # Reject requests with too many arguments
    SecRule &ARGS "@ge 1000" \
    "id:'200007', phase:2,t:none,log,deny,status:400,msg:'Failed to fully parse request body due to large argument count',severity:2"

     # Reject requests with parsing errors
     SecRule REQBODY_ERROR "!@eq 0" \
     "id:'200002', phase:2,t:none,log,deny,status:400,msg:'Failed to parse request body.',logdata:'%{reqbody_error_msg}',severity:2"

     SecResponseBodyMimeType text/plain text/html text/xml application/json application/xml application/problem+json

     # Reject requests with multipart errors
     SecRule MULTIPART_STRICT_ERROR "!@eq 0" \
     "id:'200003',phase:2,t:none,log,deny,status:400, \
     msg:'Multipart request body failed strict validation: \
     PE %{REQBODY_PROCESSOR_ERROR}, \
     BQ %{MULTIPART_BOUNDARY_QUOTED}, \
     BW %{MULTIPART_BOUNDARY_WHITESPACE}, \
     DB %{MULTIPART_DATA_BEFORE}, \
     DA %{MULTIPART_DATA_AFTER}, \
     HF %{MULTIPART_HEADER_FOLDING}, \
     LF %{MULTIPART_LF_LINE}, \
     SM %{MULTIPART_MISSING_SEMICOLON}, \
     IQ %{MULTIPART_INVALID_QUOTING}, \
     IP %{MULTIPART_INVALID_PART}, \
     IH %{MULTIPART_INVALID_HEADER_FOLDING}, \
     FL %{MULTIPART_FILE_LIMIT_EXCEEDED}'"

     # Reject requests with unmatched boundaries
     SecRule MULTIPART_UNMATCHED_BOUNDARY "@eq 1" \
     "id:'200004',phase:2,t:none,log,deny,msg:'Multipart parser detected a possible unmatched boundary.'"

     # Reject requests with PCRE (Perl Compatible Regular Expression) errors
     SecPcreMatchLimit 150000
     SecPcreMatchLimitRecursion 150000

     # Reject requests with ModSecurity internal errors
     SecRule TX:/^MSC_/ "!@streq 0" \
     "id:'200005',phase:2,t:none,log,deny,msg:'ModSecurity internal error flagged: %{MATCHED_VAR_NAME}'"

     # Buffer response body (512KB)
     SecResponseBodyLimit 524288
     # Process partial response bodies
     SecResponseBodyLimitAction ProcessPartial

     # Enable audit logging
     SecAuditEngine RelevantOnly
     # Log audit events to a file
     SecAuditLog /var/log/nginx/modsec_audit.log
     # Log all relevant status codes
     SecAuditLogRelevantStatus "^(?:5|4(?!04))"
     # Include additional audit log parts
     SecAuditLogParts ABIJDEFHZ

     # Temporary directory for ModSecurity
     SecTmpDir /tmp/
     # Data directory for ModSecurity
     SecDataDir /tmp/

     # Argument separator
     SecArgumentSeparator &

     # Cookie format
     SecCookieFormat 0
  '';

  modsecurityCrsConf = pkgs.writeText "modsecurity-crs.conf" ''
     ## OWASP

     # Base
     Include ${pkgs.modsecurity-crs}/share/modsecurity-crs/crs-setup.conf.example

    # Enable HTTP/3
     SecAction \
         "id:900230,phase:1,nolog,pass,t:none,\
         setvar:'tx.allowed_http_versions=HTTP/1.0 HTTP/1.1 HTTP/2 HTTP/2.0 HTTP/3 HTTP/3.0'"

     Include ${crsRulesFile}
  '';
  mkCsp = csp:
    lib.concatStringsSep "; " (
      (lib.optional (csp.scriptSrc != null) "script-src ${csp.scriptSrc}")
      ++ (lib.optional (csp.objectSrc != null) "object-src ${csp.objectSrc}")
      ++ (lib.optional (csp.baseUri != null) "base-uri ${csp.baseUri}")
      ++ (lib.optional (csp.connectSrc != null) "connect-src ${csp.connectSrc}")
      ++ (lib.optional (csp.defaultSrc != null) "default-src ${csp.defaultSrc}")
      ++ (lib.optional (csp.styleSrc != null) "style-src ${csp.styleSrc}")
      ++ (lib.optional (csp.imgSrc != null) "img-src ${csp.imgSrc}")
      ++ (lib.optional (csp.fontSrc != null) "font-src ${csp.fontSrc}")
      ++ (lib.optional (csp.frameSrc != null) "frame-src ${csp.frameSrc}")
      ++ (lib.optional (csp.workerSrc != null) "worker-src ${csp.workerSrc}")
    )
    + ";";
  mkSecurityHeaders = csp: frame: contentType: ''
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header Content-Security-Policy "${csp}" always;
    add_header Permissions-Policy "geolocation=(),midi=(),sync-xhr=(),microphone=(),camera=(self),magnetometer=(),gyroscope=(),fullscreen=(),payment=()";
    add_header Referrer-Policy 'strict-origin-when-cross-origin';
    add_header Cross-Origin-Opener-Policy same-origin;
    add_header Cross-Origin-Resource-Policy same-origin;
    add_header Cross-Origin-Embedder-Policy require-corp;
    add_header X-XSS-Protection '1; mode=block';
    add_header Alt-Svc 'h3=":443"; ma=86400';
    ${lib.optionalString (frame != null) "add_header X-Frame-Options ${frame};"}
    ${lib.optionalString (contentType != null) "add_header X-Content-Type-Options ${contentType};"}
  '';
  mkZoneName = domain: "per_ip_" + (builtins.replaceStrings ["." "*"] ["_" "wildcard"] domain);
  mkCertName = domain: builtins.replaceStrings ["*"] ["wildcard"] domain;
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
        type = types.attrsOf (types.submodule {
          options = {
            serverAliases = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Additional names for this virtual host.";
            };
            extraConfig = mkOption {
              type = types.lines;
              default = "";
              description = "Extra configuration for the virtual host.";
            };
            csp = mkOption {
              type = types.submodule {
                options = {
                  scriptSrc = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Content Security Policy script-src.";
                  };
                  objectSrc = mkOption {
                    type = types.nullOr types.str;
                    default = "'none'";
                    description = "Content Security Policy object-src.";
                  };
                  baseUri = mkOption {
                    type = types.nullOr types.str;
                    default = "'none'";
                    description = "Content Security Policy base-uri.";
                  };
                  connectSrc = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Content Security Policy connect-src.";
                  };
                  defaultSrc = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Content Security Policy default-src.";
                  };
                  styleSrc = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Content Security Policy style-src.";
                  };
                  imgSrc = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Content Security Policy img-src.";
                  };
                  fontSrc = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Content Security Policy font-src.";
                  };
                  frameSrc = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Content Security Policy frame-src.";
                  };
                  workerSrc = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Content Security Policy worker-src.";
                  };
                };
              };
              default = {};
            };
            frame = mkOption {
              type = types.nullOr (types.enum ["DENY" "SAMEORIGIN"]);
              default = "DENY";
              description = "X-Frame-Options header value (e.g., DENY, SAMEORIGIN).";
            };
            contentType = mkOption {
              type = types.nullOr (types.enum ["nosniff"]);
              default = "nosniff";
              description = "X-Content-Type-Options header value (e.g., nosniff).";
            };
            rateLimit = mkOption {
              description = "Rate limiting configuration.";
              default = {};
              type = types.submodule {
                options = {
                  enable = mkOption {
                    type = types.bool;
                    default = true;
                    description = "Enable rate limiting.";
                  };
                  rate = mkOption {
                    type = types.str;
                    default = "10r/s";
                    description = "Rate limit (e.g. 10r/s).";
                  };
                  burst = mkOption {
                    type = types.int;
                    default = 20;
                    description = "Burst limit.";
                  };
                  nodelay = mkOption {
                    type = types.bool;
                    default = true;
                    description = "Apply nodelay.";
                  };
                };
              };
            };
            enableWebsockets = mkOption {
              type = types.bool;
              default = false;
              description = "Enable WebSocket support (adds Upgrade headers and disables buffering).";
            };
            enableModsecurity = mkOption {
              type = types.bool;
              default = true;
              description = "Enable ModSecurity for this host.";
            };
            enableCrs = mkOption {
              type = types.bool;
              default = true;
              description = "Enable OWASP Core Rule Set for this host.";
            };
            dnsProvider = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "DNS Provider for ACME (e.g. cloudflare).";
            };
            acmeCredentialsFile = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Path to the credentials file for the DNS provider.";
            };
          };
        });
      };
      dnsProvider = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Default DNS Provider for ACME (e.g. cloudflare).";
      };
      acmeCredentialsFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Default path to the credentials file for the DNS provider.";
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
        package = pkgs.nginxMainline.override {
          withQuic = true;
          modules = [
            pkgs.nginxModules.modsecurity
            pkgs.nginxModules.moreheaders
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

          # Clear Server header
          more_clear_headers Server;

          # Rate Limiting Zones
          ${concatStringsSep "\n" (mapAttrsToList (
              domain: hostCfg:
                optionalString hostCfg.rateLimit.enable "limit_req_zone $binary_remote_addr zone=${mkZoneName domain}:10m rate=${hostCfg.rateLimit.rate};"
            )
            cfg.hosts)}

          map $http_upgrade $connection_upgrade {
            default upgrade;
            ""      close;
          }
        '';

        virtualHosts =
          mapAttrs (domain: hostCfg: let
            provider =
              if hostCfg.dnsProvider != null
              then hostCfg.dnsProvider
              else cfg.dnsProvider;
            certName = mkCertName domain;
          in {
            enableACME = provider == null;
            useACMEHost =
              if provider != null
              then certName
              else null;
            forceSSL = true;
            http2 = true;
            quic = true;
            http3 = true;
            serverAliases = hostCfg.serverAliases;
            extraConfig = ''
              ${optionalString hostCfg.rateLimit.enable ''
                limit_req zone=${mkZoneName domain} burst=${toString hostCfg.rateLimit.burst} ${optionalString hostCfg.rateLimit.nodelay "nodelay"};
              ''}
              ${optionalString (!hostCfg.enableModsecurity) "modsecurity off;"}
              ${optionalString (hostCfg.enableModsecurity && hostCfg.enableCrs) "modsecurity_rules_file ${modsecurityCrsConf};"}
              ${optionalString hostCfg.enableWebsockets ''
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection $connection_upgrade;
                proxy_buffering off;
              ''}
              ${mkSecurityHeaders (mkCsp hostCfg.csp) hostCfg.frame hostCfg.contentType}
              ${hostCfg.extraConfig}
            '';
          })
          cfg.hosts;
      };
      security.acme = {
        acceptTerms = true;
        defaults.email = cfg.acmeEmail;
        certs = let
          getProvider = hostCfg:
            if hostCfg.dnsProvider != null
            then hostCfg.dnsProvider
            else cfg.dnsProvider;
          getCreds = hostCfg:
            if hostCfg.acmeCredentialsFile != null
            then hostCfg.acmeCredentialsFile
            else cfg.acmeCredentialsFile;
          dnsHosts = filterAttrs (n: v: (getProvider v) != null) cfg.hosts;
        in
          mapAttrs' (domain: hostCfg:
            nameValuePair (mkCertName domain) {
              domain = domain;
              extraDomainNames = hostCfg.serverAliases;
              dnsProvider = getProvider hostCfg;
              credentialsFile = getCreds hostCfg;
              group = "nginx";
            })
          dnsHosts;
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
        mapAttrsToList (n: v: getPort v.listen) udpStreams ++ [443];
    };
  }
