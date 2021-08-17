{
  description = "Nix-Utils, nix utilities";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/3b6c3bee9174dfe56fd0e586449457467abe7116";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
  flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
  let
    pkgs = import nixpkgs {
      inherit system;
    };
  in {
    rpmDebUtils = pkgs.callPackage ./utils/rpm-deb {};
  });
}
