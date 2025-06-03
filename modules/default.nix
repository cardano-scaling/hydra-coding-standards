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
        mkEnableOption
        mkIf
        mkOption
        types;

    in

    {

      options.perSystem = mkPerSystemOption ({ pkgs, ... }: {
        options = {
          coding.standards.hydra = {
            enable = mkEnableOption "hydra-coding-standards";
            haskellPackages = mkOption {
              type = types.listOf types.package;
              default = [ ];
            };
            weeder = mkOption {
              type = types.package;
              default = pkgs.haskellPackages.weeder;
            };
            haskellType = mkOption {
              type = types.enum [ "nixpkgs" "haskell.nix" ];
              default = "nixpkgs";
            };
            srp-check = mkOption {
              type = types.bool;
              default = true;
            };
          };
        };
      });

      imports = [
        pinnedInputs.treefmt-nix.flakeModule
        pinnedInputs.werrorwolf.flakeModule
        pinnedInputs.weeder-part.flakeModule
      ];

      config.perSystem = { system, pkgs, config, lib, ... }:
        let
          allFiles = lib.filesystem.listFilesRecursive inputs.self;

          hcsPkgs = import pinnedPkgs { inherit system; };

          hasAnyExt = exts: file: (lib.any (ext: lib.hasSuffix ext file) exts);

          hasFilesMatching = f: lib.any f allFiles;

          hasFiles = exts: hasFilesMatching (hasAnyExt exts);

          wwpof = if config.coding.standards.hydra.haskellType == "haskell.nix" then { packageOverrideFunction = _exts: pkg: pkg.override { ghcOptions = [ "-Werror" ]; }; } else { };

        in
        with config.coding.standards.hydra; with pkgs.haskell.lib; mkIf
          enable
          {
            treefmt.programs = {
              cabal-fmt = {
                enable = hasFiles [ ".cabal" ];
                package = hcsPkgs.haskellPackages.cabal-fmt;
              };
              deadnix = {
                enable = hasFiles [ ".nix" ];
                package = hcsPkgs.deadnix;
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
              typos = {
                enable = true;
                includes = [
                  "*.md"
                  "*.hs"
                  "*.cabal"
                ];
                package = hcsPkgs.typos;
              };
            };
            checks = if (builtins.pathExists "${self}/cabal.project" && config.coding.standards.hydra.srp-check) then
              {
                no-srp = pinnedInputs.lint-utils.linters.${system}.no-srp {
                  src = self;
                  cabal-project-file = "${self}/cabal.project";
                };
              } else { };
            weeder = {
              enable = hasFiles [ ".cabal" ];
              inherit (config.coding.standards.hydra) checkPackages;
            };
            werrorwolf = {
              enable = true;
              packages = config.coding.standards.hydra.haskellPackages;
            } // wwpof;
          };
    };
}
