{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.polaris.security.secureboot;
in
  with lib; {
    options.polaris.security.secureboot = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Secure Boot";
      };
      device = mkOption {
        type = types.str;
        default = "/dev/disk/by-partlabel/disk-main-root";
        description = "Device to enroll TPM unlock";
      };
      recoveryKeyPath = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to LUKS recovery key";
      };
    };
    config = mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        sbctl
        tpm2-tss
        cryptsetup
        (writeShellScriptBin "enroll-tpm-unlock" ''
          set -e
          DEVICE="${cfg.device}"
          RECOVERY_KEY_PATH="${cfg.recoveryKeyPath}"

          if [ ! -f "$RECOVERY_KEY_PATH" ]; then
            echo "ERROR: Recovery key file not found"
            exit 1
          fi

          echo ""
          echo "You will be prompted for your current LUKS passphrase ONCE to authorize adding the recovery key."
          echo "Press Ctrl+C to cancel, or Enter to proceed..."
          read -r

          echo "Step 1: Adding recovery key..."
          ${pkgs.cryptsetup}/bin/cryptsetup luksAddKey "$DEVICE" "$RECOVERY_KEY_PATH"

          echo "Step 2 & 3: Enrolling TPM and Wiping Slot 0..."
          ${pkgs.systemd}/bin/systemd-cryptenroll \
            --tpm2-device=auto \
            --tpm2-pcrs=0+2+7+12 \
            --wipe-slot=0 \
            --unlock-key-file="$RECOVERY_KEY_PATH" \
            "$DEVICE"

          echo "The recovery key is active. Slot 0 is wiped."
        '')
      ];
    };
  }
