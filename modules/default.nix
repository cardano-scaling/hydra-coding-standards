local: {

  imports = [
    (local.flake-parts-lib.importAndPublish "hydra-coding-standards" (caller:

      let
        inherit (caller.flake-parts-lib)
          mkPerSystemOption;
        inherit (caller.lib)
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
          local.inputs.treefmt-nix.flakeModule
          local.inputs.werrorwolf.flakeModule
          local.inputs.weeder-part.flakeModule
        ];

        config.perSystem = { system, pkgs, config, lib, ... }:
          let
            allFiles = lib.filesystem.listFilesRecursive caller.self;

            hcsPkgs = import local.inputs.nixpkgs { inherit system; };

            hasAnyExt = exts: file: (lib.any (ext: lib.hasSuffix ext file) exts);

            hasFilesMatching = f: lib.any f allFiles;

            hasFiles = exts: hasFilesMatching (hasAnyExt exts);

            wwpof = if config.coding.standards.hydra.haskellType == "haskell.nix" then { packageOverrideFunction = flags: pkg: pkg.override { ghcOptions = [ "-Werror" ] ++ flags; }; } else { };

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
                    "*.agda"
                    "*.lagda"
                    "*.tex"
                  ];
                  package = hcsPkgs.typos;
                };
              };
              checks =
                if (builtins.pathExists "${caller.self}/cabal.project" && config.coding.standards.hydra.srp-check) then
                  {
                    no-srp = local.inputs.lint-utils.linters.${system}.no-srp {
                      src = caller.self;
                      cabal-project-file = "${caller.self}/cabal.project";
                    };
                  } else { };
              weeder = {
                enable = hasFiles [ ".cabal" ];
                checkPackages = config.coding.standards.hydra.haskellPackages;
                addHieOutput = config.coding.standards.hydra.haskellType == "nixpkgs";
                package = config.coding.standards.hydra.weeder;
              };
              werrorwolf = {
                enable = true;
                packages = config.coding.standards.hydra.haskellPackages;
                extra-flags = [ "-Wmissing-import-lists -Wmissing-local-signatures" ];
              } // wwpof;
            };
      }
    )
    )
  ];
}
