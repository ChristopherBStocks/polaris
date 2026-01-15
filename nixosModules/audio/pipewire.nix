{
  config,
  lib,
  ...
}: let
  cfg = config.polaris.audio.pipewire;
in
  with lib; {
    options.polaris.audio.pipewire = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Pipewire";
      };
    };
    config = mkIf cfg.enable {
      services = {
        pulseaudio.enable = lib.mkForce false;
        pipewire = {
          enable = true;
          alsa = {
            enable = true;
            support32Bit = true;
          };
          pulse.enable = true;
        };
      };
      security.rtkit.enable = true;
    };
  }
