{ config, pkgs, modulesPath, ... }:
{
  imports = [
    (import <nixos-riscv64/pkgs/sd-image-visionfive/sd-image-riscv64-visionfive2.nix>)
    (import <nixos-riscv64/nixos/visionfive2.nix>)
  ];

  nix.binaryCaches = [ "https://unmatched.cachix.org" "https://cache.chir.rs/" ];
  nix.binaryCachePublicKeys = [ "unmatched.cachix.org-1:F8TWIP/hA2808FDABsayBCFjrmrz296+5CQaysosTTc=" "nixcache:8KKuGz95Pk4UJ5W/Ni+pN+v+LDTkMMFV4yrGmAYgkDg=" ];
}
