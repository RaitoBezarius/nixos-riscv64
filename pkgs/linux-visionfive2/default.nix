{ lib, stdenv, fetchFromGitHub, buildLinux, ... } @ args:

buildLinux (args // {
  version = "5.15.0";

  src = fetchFromGitHub {
    owner = "starfive-tech";
    repo = "linux";
    rev = "JH7110_VisionFive2_devel";
    sha256 = lib.fakeHash;
  };

  defconfig = "starfive_visionfive2_defconfig";

  structuredExtraConfig = with lib.kernel; {
    SOC_STARFIVE = yes;
    CLK_STARFIVE_JH7110_SYS = yes;
    RESET_STARFIVE_JH7110 = yes;
    PINCTRL_STARFIVE_JH7110 = yes;
    SERIAL_8250_DW = yes;
    MMC_DW_STARFIVE = yes;
  };
}) // (args.argsOverride or {})
