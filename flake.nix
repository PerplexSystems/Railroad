{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    addlicense.url = "github:PerplexSystems/addlicense";
  };

  outputs = { self, nixpkgs, devenv, addlicense, ... } @ inputs:
    let
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: builtins.listToAttrs (map (name: { inherit name; value = f name; }) systems);

      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ addlicense.outputs.overlays.default ];
      });
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages."${system}";
        in
        {
          docs = pkgs.stdenv.mkDerivation {
            name = "docs";
            src = ./.;

            installPhase = ''
              mkdir -p $out

              # remove first heading
              sed -i '1d' README.md

              # add frontmatter to markdown file, required by hugo
              sed -i '1s/^/---\ntitle: Railroad\n---\n\n/' README.md

              cp README.md $out/Railroad.md
              cp -r docs $out/
            '';
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [{
              packages = with pkgs; [
                # compilers
                mlton

                # tools
                addlicense.outputs.packages."${system}".default
                millet
                smlfmt

                # other
                gnumake
                gcc
              ];
            }];
          };
        });
    };
}
