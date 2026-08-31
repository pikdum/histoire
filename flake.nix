{
  description = "Nix flake for the histoire Elixir release";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = lib.genAttrs supportedSystems;
      mkPkgs = system: import nixpkgs { inherit system; };
      mkPackage =
        pkgs:
        let
          beamPackages =
            pkgs.beam_minimal.packages.erlang_29.overrideScope (
              _final: previous: { elixir = previous.elixir_1_20; }
            );
          lexborRevision = "244b84956a6dc7eec293781d051354f351274c46";
          lexbor = pkgs.fetchFromGitHub {
            owner = "lexbor";
            repo = "lexbor";
            rev = lexborRevision;
            hash = "sha256-Oup/lGU8a9Dqfho4Llg39t9Y9n4xfUmGk0772OkpnLQ=";
          };
          src = pkgs.lib.cleanSource ./.;
        in
        beamPackages.mixRelease rec {
          pname = "histoire";
          version = "0.1.0";
          inherit src;

          mixReleaseName = "histoire";
          removeCookie = false;

          env.XDG_CACHE_HOME = "/build/.cache";

          mixFodDeps = beamPackages.fetchMixDeps {
            pname = "mix-deps-${pname}";
            inherit src version;
            hash = "sha256-zdB4PgD87BA6vnM+o30Okor82xbipcgqGfvLxJpNoEs=";
          };

          nativeBuildInputs = [ pkgs.cmake ];

          preConfigure = ''
            mkdir -p "$XDG_CACHE_HOME"

            lexbor_dir="$MIX_DEPS_PATH/lazy_html/_build/c/third_party/lexbor/${lexborRevision}"
            mkdir -p "$lexbor_dir"
            cp --no-preserve=mode -R ${lexbor}/. "$lexbor_dir/"

            cat >> config/config.exs <<EOF
            config :elixir_make, :force_build, lazy_html: true
            EOF
          '';

          preBuild = ''
            export MIX_ESBUILD_PATH="${pkgs.esbuild}/bin/esbuild"
            export MIX_TAILWIND_PATH="${pkgs.tailwindcss_4}/bin/tailwindcss"
            mix do compile --no-deps-check + tailwind histoire --minify + esbuild histoire --minify + phx.digest
          '';

          meta = with pkgs.lib; {
            description = "Source-shaped anime metadata mirror and reconciliation service";
            mainProgram = "histoire";
            platforms = platforms.linux;
          };
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          package = mkPackage (mkPkgs system);
        in
        {
          default = package;
          histoire = package;
        }
      );
    };
}
