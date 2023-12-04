{
  description = "Advent of Code 2023 in Zig!";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
    zls.url = "github:zigtools/zls";
    zls.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, zig-overlay, zls, ... }:
    with flake-utils.lib;
    eachSystem allSystems (system:
      let
        overlays = [
          zig-overlay.overlays.default
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
      in
      with pkgs;
      {
        devShell = mkShell {
          buildInputs = [
            zigpkgs.master
            zls.packages.${system}.default
          ];

          shellHook = ''
            # none
          '';
        };
      }
    );
}
