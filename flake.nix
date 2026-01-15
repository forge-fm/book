{
  description = "Rust development environment with mdbook tools";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      rust-overlay,
    }:

    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
        "aarch64-linux"
      ];
      perSystem =
        { system, self', ... }:
        let
          overlays = [ (import rust-overlay) ];
          pkgs = import nixpkgs {
            inherit system overlays;
          };
        in
        {
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              # Rust toolchain
              rust-bin.stable.latest.default

              # mdbook and plugins
              mdbook
              mdbook-admonish
              mdbook-katex
            ];

            shellHook = ''
              echo "      Rust development environment loaded"
              echo "Rust v     ersion: $(rustc --version)"
              echo "Cargo versi        on: $(cargo --version)"
              echo "mdbook version: $(mdbook --version)"
            '';
          };
        };
    };
}
