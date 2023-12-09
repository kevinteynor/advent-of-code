{
  description = "rust aoc dev env";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, fenix, ... }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ fenix.overlays.default ];
    };
  in {
    devShells."${system}" = {
      default = pkgs.mkShell {
        packages = with pkgs; [
          fenix.packages.${system}.default.toolchain
          rust-analyzer-nightly
        ];
        shellHook = ''
          echo 2023 AOC rust
          rustc --version
          cargo --version
        '';
      };
    };
  };
}
