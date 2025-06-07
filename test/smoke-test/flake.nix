{

  description = "hydra-coding-standards test flake";

  inputs = {
    get-flake.url = "github:ursi/get-flake";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs: with inputs.flake-parts.lib; mkFlake { inherit inputs; } (inputs.import-tree ./modules);

}
