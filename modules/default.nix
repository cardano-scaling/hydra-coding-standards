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
            haskellPackages = mkOption {
              type = types.listOf types.attrs;
              default = [ ];
            };
            weeder = mkOption {
              type = types.package;
              default = pkgs.haskellPackages.weeder;
            };
          };
        };
      });

      imports = [
        pinnedInputs.treefmt-nix.flakeModule
      ];

      config.perSystem = { system, pkgs, config, lib, ... }:
        let
          allFiles = lib.filesystem.listFilesRecursive inputs.self;

          hcsPkgs = import pinnedPkgs { inherit system; };

          hasAnyExt = exts: file: (lib.any (ext: lib.hasSuffix ext file) exts);

          hasFilesMatching = f: lib.any f allFiles;

          hasFiles = exts: hasFilesMatching (hasAnyExt exts);

          filterFiles = f: builtins.filter f allFiles;

          cabalFiles = filterFiles (hasAnyExt [ ".cabal" ]);

          addWerror = x: x.override { ghcOptions = [ "-Werror" ]; };

          componentsToHieDirectories = x:
            [ x.components.library.hie ]
            ++ lib.concatLists
              (map
                (y:
                  lib.mapAttrsToList
                    (k: v:
                      v.hie
                    )
                    x.components."${y}") [ "benchmarks" "exes" "sublibs" "tests" ]);

          componentsToWeederArgs = x:
            builtins.concatStringsSep " " (map (z: "--hie-directory ${z}") (componentsToHieDirectories x));

          weeder = pkgs.runCommand "weeder" { buildInputs = [ config.coding.standards.hydra.weeder ]; } ''
            mkdir -p $out
            weeder --config ${self}/weeder.toml \
              ${builtins.concatStringsSep " " (map componentsToWeederArgs config.coding.standards.hydra.haskellPackages)}
          '';

          componentsToWerrors = n: x:
            builtins.listToAttrs
              [
                {
                  name = "${n}-werror";
                  value = addWerror x.components.library;
                }
              ] // lib.attrsets.mergeAttrsList (map
              (y:
                lib.mapAttrs'
                  (k: v: {
                    name = "${n}-${y}-${k}-werror";
                    value = addWerror v;
                  })
                  x.components."${y}") [ "benchmarks" "exes" "sublibs" "tests" ]);

          allWerrors = lib.attrsets.mergeAttrsList (map (x: componentsToWerrors x.components.library.package.identifier.name x) config.coding.standards.hydra.haskellPackages);

        in
        with config.coding.standards.hydra; with pkgs.haskell.lib; mkIf enable
          {
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
            checks = (mkIf (hasFiles [ ".hs" ]) { inherit weeder; }) // allWerrors;
          };
    };
}
