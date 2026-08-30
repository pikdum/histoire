{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  dotenv.enable = true;

  languages.nix.enable = true;
  languages.elixir = {
    enable = true;
    package = pkgs.beam29Packages.elixir_1_20;
  };

  services.postgres = {
    enable = true;
    package = pkgs.postgresql_18;
    listen_addresses = "127.0.0.1";
    port = 5432;
    initialScript = ''
      CREATE ROLE postgres SUPERUSER LOGIN PASSWORD 'postgres';
    '';
    initialDatabases = [
      { name = "anime_data_dev"; }
      { name = "anime_data_test"; }
    ];
  };

}
