{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.homeManager.internet.firefox;
in
  with lib; {
    options.polaris.homeManager.internet.firefox = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Firefox";
      };
      disableFirstStart = mkOption {
        type = types.bool;
        default = true;
        description = "Disable Firefox first start";
      };
      bookmarkVisibility = mkOption {
        type = types.enum ["never" "always"];
        default = "never";
        description = "Firefox bookmark toolbar visibility";
      };
      syncEnabled = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Firefox Sync";
      };
      passwordManagerEnabled = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Firefox Password Manager";
      };
      autoEnableExtensions = mkOption {
        type = types.bool;
        default = false;
        description = "Auto-enable Extensions";
      };
      sidebar = mkOption {
        type = types.submodule {
          options = {
            position = mkOption {
              type = types.enum ["left" "right"];
              default = "left";
              description = "Sidebar position (only useful with vertical layout)";
            };
            layout = mkOption {
              type = types.enum ["vertical" "horizontal"];
              default = "vertical";
              description = "Sidebar layout";
            };
            tools = mkOption {
              type = types.str;
              default = " ";
              description = "Sidebar tools";
            };
          };
        };
        default = {};
        description = "Firefox sidebar settings";
      };
      search = mkOption {
        type = types.submodule {
          options = {
            force = mkOption {
              type = types.bool;
              default = true;
              description = "Force search settings";
            };
            default = mkOption {
              type = types.enum ["ddg"];
              default = "ddg";
              description = "Default search engine";
            };
            allowed = mkOption {
              type = types.listOf (types.enum ["ddg"]);
              default = ["ddg"];
              description = "Allowed search engines";
            };
          };
        };
        default = {};
        description = "Firefox search settings";
      };
    };
    config = mkIf cfg.enable {
      programs.firefox = {
        enable = true;
        profiles = {
          default = {
            id = 0;
            name = "default";
            isDefault = true;
            bookmarks = {};
            settings = {
              # First Start
              "browser.disableResetPrompt" = cfg.disableFirstStart; # Don’t show “Reset Firefox” prompt.
              "browser.download.panel.shown" = cfg.disableFirstStart; # Marks the download panel as already shown (suppresses the “new feature” popup).
              "browser.feeds.showFirstRunUI" = !cfg.disableFirstStart; # Skip first-time RSS/feeds UI.
              "browser.messaging-system.whatsNewPanel.enabled" = !cfg.disableFirstStart; # Disables “What’s New” panel messages.
              "browser.rights.3.shown" = cfg.disableFirstStart; # Marks that the user has already seen the rights/license info.
              "browser.shell.checkDefaultBrowser" = !cfg.disableFirstStart; # Don’t ask to set Firefox as the default browser.
              "browser.shell.defaultBrowserCheckCount" = 1; # Counter for how many times Firefox checked default browser status (set to 1 to suppress re-checks).
              "browser.startup.homepage_override.mstone" = "ignore"; # Suppresses the “Firefox updated” first-run/startup page.
              "browser.uitour.enabled" = !cfg.disableFirstStart; # Disables “tour” popups/tutorials.
              "trailhead.firstrun.didSeeAboutWelcome" = cfg.disableFirstStart; # Marks the welcome screen as already seen.
              "browser.bookmarks.restore_default_bookmarks" = !cfg.disableFirstStart; # Prevents Firefox from re-adding the default bookmarks on first run.
              "browser.bookmarks.addedImportButton" = cfg.disableFirstStart; # Mark the import bookmarks button as already added.

              # Sidebar
              "sidebar.position.start" =
                if cfg.sidebar.position == "left"
                then true
                else false;
              "sidebar.main.tools" = cfg.sidebar.tools;
              "sidebar.verticalTabs" =
                if cfg.sidebar.layout == "vertical"
                then true
                else false;

              # Misc
              "browser.toolbars.bookmarks.visibility" = cfg.bookmarkVisibility;
              "identity.fxaccounts.enabled" = cfg.syncEnabled; # Disables Firefox Sync
              "signon.rememberSignons" = cfg.passwordManagerEnabled; # Disables Firefox Password Manager
              "extensions.autoDisableScopes" =
                if cfg.autoEnableExtensions
                then 1
                else 0; # Auto-enable Extensions;
            };
            search = {
              force = true;
              default = cfg.search.default;
              order = cfg.search.allowed;
            };
          };
        };
      };
    };
  }
