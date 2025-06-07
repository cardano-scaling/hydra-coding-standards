{

  perSystem = { pkgs, lib, ... }: {
    coding.standards.hydra = {
      enable = true;
      haskellPackages = [ pkgs.haskellPackages.hello ];
    };
    weeder.enable = lib.mkForce false;
  };

}
