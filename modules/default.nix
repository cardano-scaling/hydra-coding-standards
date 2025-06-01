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
          };
        };
      });

      imports = [
        pinnedInputs.treefmt-nix.flakeModule
        pinnedInputs.werrorwolf.flakeModule
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

          weederHieArgs = builtins.concatStringsSep " " (map (z: "--hie-directory ${z.hie}") config.coding.standards.hydra.haskellPackages);

          weeder = pkgs.runCommand "weeder" { buildInputs = [ config.coding.standards.hydra.weeder ]; } ''
            mkdir -p $out
            weeder --config ${self}/weeder.toml ${weederHieArgs}
          '';

          wwpof = if config.coding.standards.hydra.haskellType == "haskell.nix" then { packageOverrideFunction = exts: pkg: pkg.override { ghcOptions = [ "-Werror" ]; }; } else { };

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
            checks = (if (builtins.pathExists "${self}/cabal.project") then
              {
                no-srp = pinnedInputs.lint-utils.linters.${system}.no-srp {
                  src = self;
                  cabal-project-file = "${self}/cabal.project";
                };
              } else { }) // (if (hasFiles [ ".hs" ]) then { inherit weeder; } else { });
            werrorwolf = {
              enable = true;
              packages = config.coding.standards.hydra.haskellPackages;
            } // wwpof;
          };
    };
}
