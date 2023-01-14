{ lib, stdenv, fetchFromGitHub, buildLinux, ... } @ args:

buildLinux (args // {
  version = "6.1.0-rc5";

  src = fetchFromGitHub {
    owner = "starfive-tech";
    repo = "linux";
    # rev = "JH7110_VisionFive2_devel";
    rev = "JH7110_VisionFive2_upstream";
    # sha256 = "sha256-zh1tonlqEY1KE2wHz1Rq8wGXZoC7Dw5U4sDYnQM3JUA=";
    sha256 = "sha256-yjIgLlsuYjOPv52m7pftkeGkiwFAFugFgzFvWK3ZBpU=";
  };

  # defconfig = "starfive_visionfive2_defconfig";
  defconfig = "defconfig";

  structuredExtraConfig = with lib.kernel; {
    SOC_STARFIVE = yes;
    CLK_STARFIVE_JH7110_SYS = yes;
    RESET_STARFIVE_JH7110 = yes;
    PINCTRL_STARFIVE_JH7110 = yes;
    SERIAL_8250_DW = yes;
    MMC = yes;
    MMC_DW = yes;
    MMC_DW_STARFIVE = yes;
  };
}) // (args.argsOverride or {})
