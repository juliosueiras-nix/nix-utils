{ stdenv, referencesByPopularity, bundlerApp, rpm }:

let
  fpm = (bundlerApp {
    pname = "fpm";
    gemdir = ./fpm;
    exes = [ "fpm" ];
  });

  buildFakeRPMDep = pkg: stdenv.mkDerivation {
    name = "rpm-multi-${pkg.name}-deps";
    buildInputs = [ fpm rpm ];

    unpackPhase = "true";

    buildPhase = ''
      export HOME=$PWD
      mkdir -p ./nix/store/
      touch deps
      for item in $(cat ${referencesByPopularity pkg})
      do
        if [ "$item" != "${pkg}" ]; then
          cp -r $item ./nix/store/
          chmod -R a+rwx .$item
          fpm -s dir -t rpm --name storepath-$(basename $item) nix
          echo storepath-$(basename $item) >> deps
          rm -r .$item
        fi
      done
    '';

    installPhase = ''
      mkdir -p $out
      cp -r *.rpm $out
      cp deps $out/
    '';
  };

  buildFakeDebDep = pkg: stdenv.mkDerivation {
    name = "deb-multi-${pkg.name}-deps";
    buildInputs = [ 
      (bundlerApp {
        pname = "fpm";
        gemdir = ./fpm;
        exes = [ "fpm" ];
      })
    ];

    unpackPhase = "true";

    buildPhase = ''
      export HOME=$PWD
      mkdir -p ./nix/store/
      touch deps
      for item in $(cat ${referencesByPopularity pkg})
      do
        if [ "$item" != "${pkg}" ]; then
          cp -r $item ./nix/store/
          chmod -R a+rwx .$item
          fpm -s dir -t deb --name storepath-$(basename $item) nix
          echo storepath-$(basename $item) >> deps
          rm -r .$item
        fi
      done
    '';

    installPhase = ''
      mkdir -p $out
      cp -r *.deb $out
      cp deps $out/
    '';
  };
in { 
  buildFakeSingleRPM = pkg: stdenv.mkDerivation {
    name = "rpm-single-${pkg.name}";
    buildInputs = [ fpm rpm ];

    unpackPhase = "true";

    buildPhase = ''
      export HOME=$PWD
      mkdir -p ./nix/store/
      mkdir -p ./bin
      for item in "$(cat ${referencesByPopularity pkg})"
      do
        cp -r $item ./nix/store/
      done

      cp -r ${pkg}/bin/* ./bin/

      chmod -R a+rwx ./nix
      chmod -R a+rwx ./bin
      fpm -s dir -t rpm --name ${pkg.name} -v ${pkg.version} nix bin
    '';

    installPhase = ''
      mkdir -p $out
      cp -r *.rpm $out
    '';
  };

  buildFakeMultiRPM = pkg: stdenv.mkDerivation {
    name = "rpm-multi-${pkg.name}";
    buildInputs = [ fpm rpm ];

    unpackPhase = "true";

    buildPhase = ''
      export HOME=$PWD
      mkdir -p ./nix/store/
      mkdir -p ./bin
      cp -r ${pkg} ./nix/store/
      cp -r ${pkg}/bin/* ./bin

      chmod -R a+rwx ./nix ./bin

      fpm -s dir -t rpm $(cat ${
        buildFakeRPMDep pkg
      }/deps | xargs -I % echo "-d %" | tr '\n' ' ') --name storepath-$(basename ${pkg}) nix bin
    '';

    installPhase = ''
      mkdir -p $out/deps
      cp -r ${buildFakeRPMDep pkg}/*.rpm $out/deps
      cp -r *.rpm $out
    '';
  };

  buildFakeSingleDeb = pkg: stdenv.mkDerivation {
    name = "deb-single-${pkg.name}";
    buildInputs = [
      fpm
    ];

    unpackPhase = "true";

    buildPhase = ''
      export HOME=$PWD
      mkdir -p ./nix/store/
      mkdir -p ./bin
      for item in "$(cat ${referencesByPopularity pkg})"
      do
        cp -r $item ./nix/store/
      done

      cp -r ${pkg}/bin/* ./bin/

      chmod -R a+rwx ./nix
      chmod -R a+rwx ./bin
      fpm -s dir -t deb --name ${pkg.name} -v ${pkg.version} nix bin
    '';

    installPhase = ''
      mkdir -p $out
      cp -r *.deb $out
    '';
  };

  buildFakeMultiDeb = pkg: stdenv.mkDerivation {
    name = "deb-multi-${pkg.name}";
    buildInputs = [ 
      (bundlerApp {
        pname = "fpm";
        gemdir = ./fpm;
        exes = [ "fpm" ];
      })
    ];

    unpackPhase = "true";

    buildPhase = ''
      export HOME=$PWD
      mkdir -p ./nix/store/
      mkdir -p ./bin
      cp -r ${pkg} ./nix/store/
      cp -r ${pkg}/bin/* ./bin

      chmod -R a+rwx ./nix ./bin

      fpm -s dir -t deb $(cat ${
        buildFakeDebDep pkg
      }/deps | xargs -I % echo "-d %" | tr '\n' ' ') --name storepath-$(basename ${pkg}) nix bin
    '';

    installPhase = ''
      mkdir -p $out/deps
      cp -r ${buildFakeDebDep pkg}/*.deb $out/deps
      cp -r *.deb $out
    '';
  };
}
