# hydra-coding-standards

[flake-parts](https://github.com/hercules-ci/flake-parts) module to set coding standards for hydra projects.

This module will automatically detect filetypes used in the client
repository and enable certain checks and formatting options.

You can reformat with `nix fmt`.

This combines the following flake-parts modules into a single module and sets
defaults:

* [treefmt-nix](https://github.com/numtide/treefmt-nix)
* [weeder-part](https://github.com/cardano-scaling/weeder-part)
* [werrorwolf](https://gitlab.horizon-haskell.net/nix/werrorwolf)

## Usage

You can enable this and set the options like so:

```{.nix}
{

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    hydra-coding-standards.url = "github:cardano-scaling/hydra-coding-standards"
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {

    imports = [
      inputs.hydra-coding-standards.flakeModule
    ];

    perSystem = { ... }: {
      coding.standards.hydra = {
        enable = true;
        haskellPackages = [
          /* haskell packages go here */
        ];
        haskellType = "haskell.nix"; -- Can be "nixpkgs" or "haskell.nix".
        weeder = myWeeder; -- For a custom weeder.
      };
    };

  };

}
```

Automatically enables and enforces `fourmolu`, `nixpkgs-fmt` and `cabal-fmt` formatters if the respective filetypes are present.

Automatically enables and enforces `statix` and `hlint` analysers if the respective filetypes are present.

Automatically enables and enforces `weeder` checks for all listed packages.

Automatically enables and enforces `-Werror` checks for all listed packages.

Automatically prohibits `source-repository-packages` in `cabal.project` files.


If you need to forcibly disable or override one of these, use the module
options directly with `lib.mkForce`.

```
  perSystem = { lib, ... }: {
    treefmt-nix.programs.statix.enable = lib.mkForce false;
  };
```
