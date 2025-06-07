{

  description = "hydra-coding-standards - flake-parts module to set all coding checks and formatters for hydra projects.";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    lint-utils = {
      url = "github:homotopic/lint-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    weeder-part.url = "github:cardano-scaling/weeder-part/0.1.0";
    werrorwolf.url = "git+https://gitlab.horizon-haskell.net/nix/werrorwolf?ref=refs/tags/0.3.0";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

}
