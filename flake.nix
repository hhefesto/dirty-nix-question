{
  description = "Question on custom nix registering as dirty";

  inputs = {
    haskellNix.url = "github:input-output-hk/haskell.nix";
    nix.url = "github:neilmayhew/nix?rev=f6f5f9805a12737c4345b453886c5c07f1d6ccb5";
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nix, nixpkgs, flake-compat, haskellNix }:
    let
      nix-patched = import nix;
      overlays = [
        haskellNix.overlay
        (final: prev: {
            hello-world =
              final.haskell-nix.stackProject' {
                src = ./.;
              };
          })
        (final: prev: {
          nix = nix-patched.packages.x86_64-linux.default;
        })
      ];
      pkgs = import nixpkgs {
        inherit overlays;
        inherit (haskellNix) config;
        system = "x86_64-linux";
      };
      flake = pkgs.hello-world.flake {};

    in flake // {
        packages = flake.packages // {
          default = flake.packages."hello-world:exe:hello-world";
        };
        legacyPackages = pkgs;
      };

  nixConfig = {
    # This sets the flake to use the IOG nix cache.
    # Nix should ask for permission before using it,
    # but remove it here if you do not want it to.
    extra-substituters = ["https://cache.iog.io"];
    extra-trusted-public-keys = ["hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
    allow-import-from-derivation = "true";
  };
}
