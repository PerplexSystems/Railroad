{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, devenv, ... } @ inputs:
    let
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: builtins.listToAttrs (map (name: { inherit name; value = f name; }) systems);
    in
      {
        packages = forAllSystems (system:
          let
            pkgs = nixpkgs.legacyPackages."${system}";
          in {
            docs = pkgs.stdenv.mkDerivation {
              name = "docs";
              src = ./.;

              installPhase = ''
                mkdir -p $out
                
                # remove first heading
                sed -i '1d' README.md

                # add frontmatter to markdown file, required by hugo
                sed -i '1s/^/---\ntitle: smltest\n---\n\n/' README.md
                
                cp README.md $out/smltest.md
                cp -r docs $out/
              '';
            };
          });

      apps = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          mlton = "${pkgs.mlton}/bin/mlton";
          mktemp = "${pkgs.coreutils}/bin/mktemp";
        in {
          test = {
            type = "app";
            program = toString (pkgs.writeShellScript "run-tests" ''
              output=$(${mktemp})
              ${mlton} -output $output tests/tests.mlb && $output
            '');
          };

          build = {
            type = "app";
            program = toString (pkgs.writeShellScript "build-program" ''
              output=$(${mktemp})
              ${mlton} -output $output sources.mlb && echo "Successfully built!"
            '');
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
                mlton lunarml

                # tools
                millet smlfmt 
                
                # other
                gnumake gcc 
              ];
            }];
          };
        });
    };
}
