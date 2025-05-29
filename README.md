# hydra-coding-standards

[flake-parts](https://github.com/hercules-ci/flake-parts) module to set coding standards for hydra projects.

This module will automatically detect filetypes used in the client
repository and enable certain checks and formatting options.

You can reformat with `nix fmt`.

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
      coding.standards.hydra.enable = true;
    };

  };

}
```

Automatically enables and enforces `fourmolu`, `nixpkgs-fmt` and `cabal-fmt` formatters if the respective filetypes are present.
Automatically enables and enforces `statix` and `hlint` analysers if the respective filetypes are present.
Automatically enables and enforces `weeder` checks for all listed packages.
Automatically enables and enforces `-Werror` checks for all listed packages.
Automatically prohibits `source-repository-packages` in `cabal.project` files.
