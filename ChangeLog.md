# ChangeLog for `hydra-coding-standards`.

## 0.5.0

* Import `werrorwolf-0.3.0` and set `-Werror` checks correctly.
* Add `haskellType` setting to switch between `nixpkgs` style and `haskell.nix` style.

## 0.4.1

* Add `no-srp` check from `lint-utils`.

## 0.4.0

* Remove `fourmolu` settings.

## 0.3.1

* Fix executable name of `fourmolu-wrapped`.

## 0.3.0

* Add `fourmolu` settings.

## 0.2.0

* Add `werror` checks and `weeder` check for all listed `haskellPackages`.

## 0.1.0

* Initial commit of `hydra-coding-standards`.
* Enables `cabal-fmt`, `fourmolu`, `hlint`, `nixpkgs-fmt`, and `statix`.
