# `nixos/modules/installer/sd-card/sd-image.nix` patched for VisionFive.
#
# The VisionFive board ships with a build of U-Boot where normal Distro Boot
# does not work at all (extlinux.conf, boot.scr, or EFI) because of the lack
# of expected environment variables such as `scriptaddr` and `kernel_addr_r`.
# It does load `/boot/uEnv.txt` from the third partition of the SD card
# (hardcoded), which is what the official Fedora image uses to set those
# environment variables and runs bootefi.
#
# tl;dr: The factory U-Boot build is broken. The official Fedora image doesn't
# just use "normal UEFI." It uses a `uEnv.txt` which must reside in a specific
# partition to initiate the EFI boot.
#
# Here we do the same thing so the resulting image works with factory U-Boot :(

{ config, lib, pkgs, modulesPath, ... }:

with lib;

let
  rootfsImage = pkgs.callPackage (pkgs.path + "/nixos/lib/make-ext4-fs.nix") ({
    inherit (config.sdImage) storePaths;
    compressImage = true;
    populateImageCommands = config.sdImage.populateRootCommands;
    volumeLabel = "NIXOS_SD";
  } // optionalAttrs (config.sdImage.rootPartitionUUID != null) {
    uuid = config.sdImage.rootPartitionUUID;
  });
in
{
  imports = [
    (mkRemovedOptionModule [ "sdImage" "bootPartitionID" ] "The FAT partition for SD image now only holds the Raspberry Pi firmware files. Use firmwarePartitionID to configure that partition's ID.")
    # (mkRemovedOptionModule [ "sdImage" "bootSize" ] "The boot files for SD image have been moved to the main ext4 partition. The FAT partition now only holds the Raspberry Pi firmware files. Changing its size may not be required.")
    (modulesPath + "/profiles/all-hardware.nix")
  ];

  options.sdImage = {
    imageName = mkOption {
      default = "${config.sdImage.imageBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.img";
      description = ''
        Name of the generated image file.
      '';
    };

    imageBaseName = mkOption {
      default = "nixos-sd-image";
      description = ''
        Prefix of the name of the generated image file.
      '';
    };

    storePaths = mkOption {
      type = with types; listOf package;
      example = literalExpression "[ pkgs.stdenv ]";
      description = ''
        Derivations to be included in the Nix store in the generated SD image.
      '';
    };

    firmwarePartitionOffset = mkOption {
      type = types.int;
      default = 8;
      description = ''
        Gap in front of the /boot/firmware partition, in mebibytes (1024×1024
        bytes).
        Can be increased to make more space for boards requiring to dd u-boot
        SPL before actual partitions.

        Unless you are building your own images pre-configured with an
        installed U-Boot, you can instead opt to delete the existing `FIRMWARE`
        partition, which is used **only** for the Raspberry Pi family of
        hardware.
      '';
    };

    firmwarePartitionID = mkOption {
      type = types.str;
      default = "0x2178694e";
      description = ''
        Volume ID for the /boot/firmware partition on the SD card. This value
        must be a 32-bit hexadecimal number.
      '';
    };

    firmwarePartitionName = mkOption {
      type = types.str;
      default = "FIRMWARE";
      description = ''
        Name of the filesystem which holds the boot firmware.
      '';
    };

    rootPartitionUUID = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "14e19a7b-0ae0-484d-9d54-43bd6fdc20c7";
      description = ''
        UUID for the filesystem on the main NixOS partition on the SD card.
      '';
    };

    firmwareSize = mkOption {
      type = types.int;
      # As of 2019-08-18 the Raspberry pi firmware + u-boot takes ~18MiB
      default = 30;
      description = ''
        Size of the /boot/firmware partition, in megabytes.
      '';
    };

    bootSize = mkOption {
      type = types.int;
      default = 100;
      description = ''
        Size of the /boot/firmware partition, in megabytes.
      '';
    };

    populateFirmwareCommands = mkOption {
      example = literalExpression "'' cp \${pkgs.myBootLoader}/u-boot.bin firmware/ ''";
      description = ''
        Shell commands to populate the ./firmware directory.
        All files in that directory are copied to the
        /boot/firmware partition on the SD image.
      '';
    };

    populateBootCommands = mkOption {
      example = literalExpression "''\${config.boot.loader.generic-extlinux-compatible.populateCmd} -c \${config.system.build.toplevel} -d ./files/boot''";
      description = ''
        Shell commands to populate the ./boot directory.
        All files in that directory are copied to the
        boot (/boot) partition on the SD image.
      '';
    };


    populateRootCommands = mkOption {
      example = literalExpression "''\${config.boot.loader.generic-extlinux-compatible.populateCmd} -c \${config.system.build.toplevel} -d ./files/boot''";
      description = ''
        Shell commands to populate the ./files directory.
        All files in that directory are copied to the
        root (/) partition on the SD image. Use this to
        populate the ./files/boot (/boot) directory.
      '';
    };

    postBuildCommands = mkOption {
      example = literalExpression "'' dd if=\${pkgs.myBootLoader}/SPL of=$img bs=1024 seek=1 conv=notrunc ''";
      default = "";
      description = ''
        Shell commands to run after the image is built.
        Can be used for boards requiring to dd u-boot SPL before actual partitions.
      '';
    };

    compressImage = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether the SD image should be compressed using
        <command>zstd</command>.
      '';
    };

    expandOnBoot = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to configure the sd image to expand it's partition on boot.
      '';
    };
  };

  config = {
    fileSystems = {
      "/boot/firmware" = {
        device = "/dev/disk/by-label/${config.sdImage.firmwarePartitionName}";
        fsType = "vfat";
        # Alternatively, this could be removed from the configuration.
        # The filesystem is not needed at runtime, it could be treated
        # as an opaque blob instead of a discrete FAT32 filesystem.
        options = [ "nofail" "noauto" ];
      };
      "/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
      };
    };

    sdImage.storePaths = [ config.system.build.toplevel ];

    system.build.sdImage = pkgs.callPackage ({ stdenv, dosfstools, e2fsprogs,
    mtools, libfaketime, util-linux, zstd }: stdenv.mkDerivation {
      name = config.sdImage.imageName;

      nativeBuildInputs = [ dosfstools e2fsprogs mtools libfaketime util-linux zstd ];

      inherit (config.sdImage) compressImage;

      buildCommand = ''
        mkdir -p $out/nix-support $out/sd-image
        export img=$out/sd-image/${config.sdImage.imageName}

        echo "${pkgs.stdenv.buildPlatform.system}" > $out/nix-support/system
        if test -n "$compressImage"; then
          echo "file sd-image $img.zst" >> $out/nix-support/hydra-build-products
        else
          echo "file sd-image $img" >> $out/nix-support/hydra-build-products
        fi

        echo "Decompressing rootfs image"
        zstd -d --no-progress "${rootfsImage}" -o ./root-fs.img

        # Gap in front of the first partition, in MiB
        gap=${toString config.sdImage.firmwarePartitionOffset}

        # Create the image file sized to fit /boot/firmware and /, plus slack for the gap.
        rootSizeBlocks=$(du -B 512 --apparent-size ./root-fs.img | awk '{ print $1 }')
        firmwareSizeBlocks=$((${toString config.sdImage.firmwareSize} * 1024 * 1024 / 512))
        bootSizeBlocks=$((${toString config.sdImage.bootSize} * 1024 * 1024 / 512))
        imageSize=$((rootSizeBlocks * 512 + firmwareSizeBlocks * 512 + bootSizeBlocks * 512))
        truncate -s $imageSize $img

        # The "bootable" partition is where u-boot will look file for the bootloader
        # information (dtbs, extlinux.conf file).
        sfdisk $img <<EOF
            label: gpt
            label-id: ${config.sdImage.firmwarePartitionID}

            start=2048, size=32768, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=00D7AFD1-99DE-42BF-9A5F-2177370C9FDC
            start=34816, size=${toString config.sdImage.bootSize}M, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, uuid=70E8FA63-F9FC-410B-8322-B0950C6D22FB
            start=239616, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=AD8195B8-7BBF-784E-8058-59E0EAA8D087
        EOF

        # Copy the rootfs into the SD image
        eval $(partx $img -o START,SECTORS --nr 3 --pairs)
        dd conv=notrunc if=./root-fs.img of=$img seek=$START count=$SECTORS

        # Create a FAT32 /boot/firmware partition of suitable size into firmware_part.img
        eval $(partx $img -o START,SECTORS --nr 1 --pairs)
        truncate -s $((SECTORS * 512)) firmware_part.img
        faketime "1970-01-01 00:00:00" mkfs.vfat -i ${config.sdImage.firmwarePartitionID} -n ${config.sdImage.firmwarePartitionName} firmware_part.img

        # Populate the files intended for /boot/firmware
        mkdir firmware
        ${config.sdImage.populateFirmwareCommands}

        # Copy the populated /boot/firmware into the SD image
        (cd firmware; mcopy -psvm -i ../firmware_part.img ./* ::)
        # Verify the FAT partition before copying it.
        fsck.vfat -vn firmware_part.img
        dd conv=notrunc if=firmware_part.img of=$img seek=$START count=$SECTORS

        # Create a FAT32 /boot partition of suitable size into boot_part.img
        eval $(partx $img -o START,SECTORS --nr 2 --pairs)
        truncate -s $((SECTORS * 512)) boot_part.img
        faketime "1970-01-01 00:00:00" mkfs.vfat -i ${config.sdImage.firmwarePartitionID} -n ${config.sdImage.firmwarePartitionName} boot_part.img

        # Populate the files intended for /boot
        mkdir boot
        ${config.sdImage.populateBootCommands}

        # Copy the populated /boot into the SD image
        (cd boot; mcopy -psvm -i ../boot_part.img ./* ::)
        # Verify the FAT partition before copying it.
        fsck.vfat -vn boot_part.img
        dd conv=notrunc if=boot_part.img of=$img seek=$START count=$SECTORS

        ${config.sdImage.postBuildCommands}

        if test -n "$compressImage"; then
            zstd -T$NIX_BUILD_CORES --rm $img
        fi
      '';
    }) {};

    boot.postBootCommands = lib.mkIf config.sdImage.expandOnBoot ''
      # On the first boot do some maintenance tasks
      if [ -f /nix-path-registration ]; then
        set -euo pipefail
        set -x
        # Figure out device names for the boot device and root filesystem.
        rootPart=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE /)
        bootDevice=$(lsblk -npo PKNAME $rootPart)
        partNum=$(lsblk -npo MAJ:MIN $rootPart | ${pkgs.gawk}/bin/awk -F: '{print $2}')

        # Resize the root partition and the filesystem to fit the disk
        echo ",+," | sfdisk -N$partNum --no-reread $bootDevice
        ${pkgs.parted}/bin/partprobe
        ${pkgs.e2fsprogs}/bin/resize2fs $rootPart

        # Register the contents of the initial Nix store
        ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration

        # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
        touch /etc/NIXOS
        ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system

        # Prevents this from running on later boots.
        rm -f /nix-path-registration
      fi
    '';
  };
}
