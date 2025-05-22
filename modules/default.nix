{ inputs, ... }:

let
  pinnedInputs = inputs;
  pinnedPkgs = inputs.nixpkgs;

in

{

  flake.flakeModule =
    { self, config, inputs, lib, flake-parts-lib, ... }:

    let
      inherit (flake-parts-lib)
        mkPerSystemOption;
      inherit (lib)
        mdDoc
        mkEnableOption
        mkIf
        mkOption
        types;

    in

    {

      options.perSystem = mkPerSystemOption ({ config, pkgs, ... }: {
        options = {
          coding.standards.hydra = {
            enable = mkEnableOption "hydra-coding-standards";
          };
        };
      });

      imports = [
        pinnedInputs.treefmt-nix.flakeModule
      ];

      config.perSystem = { system, pkgs, config, lib, ... }:
        let
          hcsPkgs = import pinnedPkgs { inherit system; };

          hasFiles = exts: lib.any (file: lib.any (ext: lib.hasSuffix ext file) exts) (lib.filesystem.listFilesRecursive inputs.self);

        in
        with config.coding.standards.hydra; with pkgs.haskell.lib; (mkIf enable {
          treefmt.programs = {
            cabal-fmt = {
              enable = hasFiles [ ".cabal" ];
              package = hcsPkgs.haskellPackages.cabal-fmt;
            };
            fourmolu = {
              enable = hasFiles [ ".hs" ];
              package = hcsPkgs.haskellPackages.fourmolu;
            };
            hlint = {
              enable = hasFiles [ ".hs" ];
              package = hcsPkgs.haskellPackages.hlint;
            };
            nixpkgs-fmt = {
              enable = hasFiles [ ".nix" ];
              package = hcsPkgs.nixpkgs-fmt;
            };
            statix = {
              enable = hasFiles [ ".nix" ];
              package = hcsPkgs.statix;
            };
          };
        });
    };
}
