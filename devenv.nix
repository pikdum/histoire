{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  languages.elixir = {
    enable = true;
    package = pkgs.beam29Packages.elixir_1_20;
  };

  languages.nix.enable = true;
}
