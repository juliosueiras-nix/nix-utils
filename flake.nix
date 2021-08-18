{
  description = "Nix-Utils, nix utilities";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
  (flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
  let
    pkgs = import nixpkgs {
      inherit system;
    };
  in {
    rpmDebUtils = pkgs.callPackage ./utils/rpm-deb {};

  })) // {
    bundlers =  with builtins; let
          pkgs = system: import nixpkgs {
            inherit system;
          };
          # Function requires a derivation along with it's meta data instead
          # of a built store path provided by `nix bundle`
          package = program: system: let
            name= (parseDrvName ( elemAt (split "/[0-9a-df-np-sv-z]{32}-" (program)) 2)).name;
            in (pkgs system).runCommand name {} ''
             mkdir -p $out/bin
             ln -s ${program} $out/bin/.
          '';
          utils = system: (pkgs system).callPackage ./utils/rpm-deb {};
             in
    {
      rpm = { program, system }: 
          (utils system).buildFakeSingleRPM (package program system);

      deb = { program, system }: 
          (utils system).buildFakeSingleDeb (package program system);

    };
    defaultBundler = self.bundlers.rpm;
  };
}
