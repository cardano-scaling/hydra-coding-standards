{ self, ... }: {
  flake.flakeModule = self.modules.flake.hydra-coding-standards;
}
