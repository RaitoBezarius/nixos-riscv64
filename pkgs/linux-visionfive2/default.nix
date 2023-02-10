{ lib, stdenv, fetchFromGitHub, buildLinux, ... } @ args:

buildLinux (args // {
  version = "5.15.0";

  src = fetchFromGitHub {
    owner = "starfive-tech";
    repo = "linux";
    rev = "JH7110_VisionFive2_upstream";
    # rev = "JH7110_VisionFive2_upstream";
    sha256 = lib.fakeHash;
    # sha256 = "sha256-o1k1UDUXUsRb4200zZ5ozVL15g7wsheet8O5UhX2HWY=";
    # sha256 = "sha256-yjIgLlsuYjOPv52m7pftkeGkiwFAFugFgzFvWK3ZBpU=";
  };

  kernelPatches = [
    { name = "crypto-dh"; patch = ./crypto-dh.patch; }
    { name = "remove-rmd128"; patch = ./0001-crypto-remove-rmd128-as-it-is-not-here-anymore.patch; }
    { name = "remove-rmd256-320-tgr192"; patch = ./0001-crypto-remove-rmd256-rmd320-tgr192-as-they-are-not-h.patch; }
    { name = "remove-salsa20"; patch = ./0001-crypto-remove-salsa20-as-they-are-not-here-anymore.patch; }
    { name = "gpu-drm-tda998x"; patch = ./gpu-drm-tda998x.patch; }
    { name = "sound-soc-starfive"; patch = ./sound-soc-starfive.patch; }
  ];

  defconfig = "starfive_visionfive2_defconfig";
  # defconfig = "defconfig";

  structuredExtraConfig = with lib.kernel; {
    # TODO(hacks): cleanup those.
    SND_SOC_WM8960 = no;
    CRYPTO_SM4 = no;
    SPI_PL022 = no;
    SPI_PL022_STARFIVE = no;
    DRM_VERISILICON = no;
    STARFIVE_INNO_HDMI = no;
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
