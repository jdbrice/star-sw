{ nixpkgs ? import <nixpkgs> {}, target }:

let
  star_nix = import <star-nix/default.nix> { inherit nixpkgs; use_32bit = false; };
  star_cvs = builtins.fetchGit {
    url = https://github.com/star-bnl/star-cvs.git;
  };
  # This should be just star_nix.stdenv, but we need CC (for preprocessor) that has fortran in it
  __stdenv = star_nix.eff_pkgs.overrideCC star_nix.eff_pkgs.stdenv star_nix.eff_pkgs.gfortran48;
in
  __stdenv.mkDerivation {
    name = "star-soft-${target}";
    nativeBuildInputs = [
      nixpkgs.cmake
      nixpkgs.utillinux
      nixpkgs.flex
      nixpkgs.bison
      nixpkgs.perl
      nixpkgs.python2
      nixpkgs.python2.pkgs.pyparsing
      ];
    buildInputs = [
      star_nix.log4cxx
      star_nix.mysql.client
      star_nix.libxml2
      star_nix.root
      star_nix.curl
      star_nix.eff_pkgs.gfortran48
      ];
    src = nixpkgs.lib.sourceByRegex ../. [
      "^CMakeLists\.txt$"
      "^StArray_cint\.h$"
      ".*\.cmake$"
      ".*\.sh$"
      "^star-aux.*"
      ];
    CC = "${star_nix.eff_pkgs.gfortran48}/bin/cc";
    CXX = "${star_nix.eff_pkgs.gfortran48}/bin/g++";
    NIX_ENFORCE_PURITY = 0;
    preConfigure = ''
      export STAR_HOST_SYS=sl73_gcc485
    '';
    cmakeFlags = [
      "-DSTAR_SRC=${star_cvs}"
      ];
    buildPhase = ''
       make ${target} -j $NIX_BUILD_CORES
    '';
    installPhase = ''
      # We can't do make install because it will trigger make all
      # so let's just make a dummy output for now
      touch $out
    '';
    enableParallelBuilding = true;
    hardeningDisable = [ "format" ];
  }
