{ lib, stdenv, fetchFromGitHub, buildLinux, ... } @ args:

buildLinux (args // {
  version = "5.15.0";

  src = fetchFromGitHub {
    owner = "starfive-tech";
    repo = "linux";
    rev = "JH7110_VisionFive2_devel";
    # rev = "JH7110_VisionFive2_upstream";
    # sha256 = "sha256-yjIgLlsuYjOPv52m7pftkeGkiwFAFugFgzFvWK3ZBpU=";
    sha256 = "sha256-o1k1UDUXUsRb4200zZ5ozVL15g7wsheet8O5UhX2HWY=";
    # sha256 = "sha256-yjIgLlsuYjOPv52m7pftkeGkiwFAFugFgzFvWK3ZBpU=";
  };

  kernelPatches = [
    { name = "crypto-dh"; patch = ./0001-security-keys-dh-dh_data_from_key-takes-const-void-d.patch; }
    { name = "remove-ciphers"; patch = ./0002-crypto-remove-old-ciphers-as-it-is-not-here-anymore.patch; }
    { name = "sound-soc-starfive"; patch = ./0003-sound-soc-starfive-remove-starfive_pwmdac_transmitte.patch; }
    { name = "gpu-drm-tda998x"; patch = ./0004-drivers-gpu-drm-i2c-tda998x_pin-use-proper-device-ta.patch; }
    { name = "verisilicon"; patch = ./0005-verisilicon-deal-with-it.patch; }
    { name = "media-starfive"; patch = ./0006-media-starfive-kill-some-modules.patch; }
    { name = "wireless-cleanup"; patch = ./0007-wireless-clean-up-SHELL-according-to-POSIX.patch; }
  ];

  defconfig = "starfive_visionfive2_defconfig";
  # defconfig = "defconfig";

  structuredExtraConfig = with lib.kernel; {
    # TODO(hacks): cleanup those.
    DEBUG_INFO_BTF = lib.mkForce no;
    DEBUG_INFO_BTF_MODULES = lib.mkForce no;
    SND_SOC_WM8960 = no;
    RTC_DRV_STARFIVE = no;
    PL330_DMA = no;
    SPI_PL022 = no;
    SPI_PL022_STARFIVE = no;
    DRM_VERISILICON = no;
    STARFIVE_INNO_HDMI = no;
    DRM_IMG_ROGUE = no;
    USB_WIFI_ECR6600U = no;
    # Required extra configuration
    SOC_STARFIVE = yes;
    CLK_STARFIVE_JH7110_SYS = yes;
    RESET_STARFIVE_JH7110 = yes;
    PINCTRL_STARFIVE_JH7110 = yes;
    SERIAL_8250_DW = yes;
    # MMC = yes;
    # MMC_DW = yes;
    # DWMAC_STARFIVE_PLAT = yes;
    # MMC_DW_STARFIVE = yes;
  };
}) // (args.argsOverride or {})
