let
  pkgs = import <nixpkgs> {};
  lib = import ./lib.nix { inherit pkgs; };
in

lib.shell

