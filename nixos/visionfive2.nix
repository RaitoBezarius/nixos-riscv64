{ pkgs, lib, ... }: {
  nixpkgs.overlays = [
    (import ../pkgs)
  ];

  hardware.deviceTree.name = "starfive/jh7110-starfive-visionfive-v2.dtb";

  boot.supportedFilesystems = lib.mkForce [ "btrfs" "vfat" "ext4" ];
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.kernelPackages = pkgs.riscv64.linuxPackages_visionfive2;
  boot.kernelParams = [
    "console=tty0" "console=ttyS0,115200" "earlycon=sbi"

    # https://github.com/starfive-tech/linux/issues/14
    "stmmac.chain_mode=1"
  ];
  boot.initrd.kernelModules = [ "dw_mmc-pltfm" "spi-dw-mmio" ];

  systemd.services."serial-getty@hvc0" = {
    enable = false;
  };

  environment.systemPackages = with pkgs; [
    mtdutils
  ];
}
