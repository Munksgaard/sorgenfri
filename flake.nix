{
  description = "A photo gallery for families";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell.url = "github:numtide/devshell";
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; }
    ({ moduleWithSystem, withSystem, ... }: {
      imports = [ inputs.devshell.flakeModule ];
      systems =
        [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          craneLib = inputs.crane.lib.${system};

          passwordHashing =
            craneLib.buildPackage { src = ./native/password_hashing; };

          pname = "sorgenfri";
          version = "0.0.1";
          src = ./.;
          tailwindCss = pkgs.nodePackages.tailwindcss.overrideAttrs (oa: {
            plugins = [ pkgs.nodePackages."@tailwindcss/forms" ];
            version = "3.4.1";
          });
          beam_pkgs = pkgs.beam.packagesWith pkgs.beam.interpreters.erlang;
          mixFodDeps = pkgs.beamPackages.fetchMixDeps {
            pname = "${pname}-deps";
            inherit src version;
            hash = "sha256-4XKKYNu+ZemIkPyH81QD+XOOcMiSeqWL6ejwdr1/LZQ=";
          };
          elixir = beam_pkgs.elixir_1_16;
          sorgenfri = beam_pkgs.mixRelease {
            inherit src pname version mixFodDeps elixir;

            buildInputs = [ pkgs.cargo pkgs.rustc ];

            ELIXIR_MAKE_CACHE_DIR = "/tmp/";

            PRECOMPILED_NIF = true;

            preBuild = ''
              mkdir -p priv/native
              cp ${passwordHashing}/lib/libpassword_hashing.so priv/native
            '';

            postBuild = ''
              # Consult https://nixos.org/manual/nixpkgs/unstable/#mix-release-example if node dependencies are needed
              # For external task you need a workaround for the no deps check flag
              # https://github.com/phoenixframework/phoenix/issues/2690
              mix do deps.loadpaths --no-deps-check, phx.digest

              mkdir -p tmp/deps
              cp -r ${mixFodDeps}/phoenix tmp/deps/phoenix
              cp -r ${mixFodDeps}/phoenix_html tmp/deps/phoenix_html

              mix deps.compile
              MIX_ESBUILD_NODE_PATH="${mixFodDeps}/" MIX_TAILWIND_PATH="${tailwindCss}/bin/tailwind" MIX_ESBUILD_PATH="${pkgs.esbuild}/bin/esbuild" mix assets.deploy

              mix phx.digest --no-deps-check
            '';
          };
        in {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.

          devshells.default = {
            devshell.name = pname;
            env = [
              {
                name = "HTTP_PORT";
                value = 8080;
              }
              {
                name = "MIX_PATH";
                value =
                  "${pkgs.beam.packages.erlang.hex}/lib/erlang/lib/hex/ebin";
              }
              {
                name = "LANG";
                value = "C.UTF-8";
              }

            ];
            commands = [{
              help = "print hello";
              name = "hello";
              command = "echo hello";
            }];
            packages = [
              elixir
              pkgs.sqlite
              pkgs.imagemagick
              pkgs.ffmpeg-full
              pkgs.inotify-tools
            ];
          };

          packages.passwordHashing = passwordHashing;
          packages.sorgenfri = sorgenfri;
          packages.default = self'.packages.sorgenfri;
        };
      flake = {
        nixosModules.sorgenfri = moduleWithSystem (perSystem@{ config }:
          nixos@{ config, options, pkgs, packages, lib, ... }:
          with lib;
          let
            name = "sorgenfri";
            cfg = config.services.sorgenfri;
            opt = options.services.sorgenfri;
          in {
            options.services.sorgenfri = {
              enable = mkEnableOption "Enables the Sorgenfri service.";

              package = mkPackageOption packages "sorgenfri" { };

              uploadDir = mkOption {
                type = types.path;
                example = lib.literalExpression "/var/lib/sorgenfri/uploads";
                default = "/var/lib/sorgenfri/uploads";
                description = "Where to save uploads.";
              };

              databasePath = mkOption {
                type = types.path;
                example = lib.literalExpression "/var/lib/sorgenfri/db.sqlite";
                default = "/var/lib/sorgenfri/db.sqlite";
                description = "Where to store the SQLite database.";
              };

              releaseTmp = mkOption {
                type = types.path;
                example = lib.literalExpression "/run/sorgenfri";
                default = "/run/sorgenfri/tmp";
                description = ''

                  The value of the RELEASE_TMP environment variable,
                  which is used to write the state of the VM
                  configuration when the system is running. It needs to
                  be a writable directory.
                '';
              };

              secretKeyBaseFile = mkOption {
                type = types.path;
                description = "File containing the secret key base.";
              };

              address = mkOption {
                type = types.str;
                default = "localhost";
                description = "Address to listen on";
              };

              port = mkOption {
                type = types.port;
                default = 8000;
                description = "Port to listen on";
              };

              smtp = {
                passwordFile = mkOption {
                  type = types.nullOr types.path;
                  default = null;
                  description = "A file containing the SMTP password.";
                };

                username = mkOption {
                  type = types.str;
                  description = "SMTP username";
                };

                port = mkOption {
                  type = types.port;
                  description = "SMTP port";
                  default = 465;
                };

                host = mkOption {
                  type = types.str;
                  description = "SMTP host";
                };
              };
            };

            # (Temporarily) add container to test module

            config = mkIf cfg.enable {
              systemd.services.sorgenfri = {
                description = "Sorgenfri Server";
                wantedBy = [ "multi-user.target" ];
                after = [ "network.target" ];
                requires = [ "network-online.target" ];

                startLimitBurst = 3;
                startLimitIntervalSec = 10;

                environment = {
                  PHX_SERVER = "true";
                  PHX_HOST = "${cfg.address}";
                  PHX_PORT = toString cfg.port;
                  RELEASE_DISTRIBUTION = "none";
                  ERL_EPMD_ADDRESS = "127.0.0.1";
                  RELEASE_TMP = cfg.releaseTmp;
                  DATABASE_PATH = cfg.databasePath;
                  SMTP_USERNAME = cfg.smtp.username;
                  SMTP_PORT = toString cfg.smtp.port;
                  SMTP_HOST = cfg.smtp.host;
                  UPLOAD_DIR = cfg.uploadDir;
                };

                serviceConfig = {
                  Type = "notify";
                  DynamicUser = true;
                  WorkingDirectory = "/run/sorgenfri";
                  StateDirectory = "sorgenfri";
                  RuntimeDirectory = "sorgenfri";
                  # Implied by DynamicUser, but just to emphasize due to RELEASE_TMP
                  PrivateTmp = true;
                  ExecStart = "${cfg.package}/bin/${name} start";
                  ExecReload = ''
                    ${cfg.package}/bin/${name} restart
                  '';
                  Restart = "on-failure";
                  RestartSec = 5;
                  LoadCredential = [
                    "SECRET_KEY_BASE:${cfg.secretKeyBaseFile}"
                    "SMTP_PASSWORD:${cfg.smtp.passwordFile}"
                  ];
                  WatchdogSec = "10s";
                  KillMode = "mixed";
                };
                # disksup requires bash
                path = [ pkgs.bash pkgs.gawk pkgs.ffmpeg pkgs.imagemagick ];

              };

            };
          });
      };
    });
}
