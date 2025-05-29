{

  perSystem = { pkgs, ... }: {
    coding.standards.hydra = {
      enable = true;
      haskellPackages = [ pkgs.haskellPackages.hello ];
    };
  };

}
