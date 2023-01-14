{
  description = "Board-Specific Packages for NixOS on RISC-V";

  inputs = {
    nixpkgs.url = "github:zhaofengli/nixpkgs/riscv";
    nixpkgs-unstable-small.url = "github:nixos/nixpkgs/nixos-unstable-small";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable-small }: let
    mkPkgs = nixpkgs: system: import nixpkgs {
      inherit system;
      overlays = [
        (final: prev: {
          nixos-riscv64 = self.outPath;
        })

        self.overlay
      ];
    };
  in {
    overlay = import ./pkgs;
    legacyPackages.riscv64-linux = mkPkgs nixpkgs "riscv64-linux";
    legacyPackages.x86_64-linux = mkPkgs nixpkgs-unstable-small "x86_64-linux";
    nixosModules = {
      unmatched = import ./nixos/unmatched.nix;
      visionfive = import ./nixos/visionfive.nix;
      visionfive2 = import ./nixos/visionfive2.nix;
    };
  };
}
