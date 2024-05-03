{ config, options, pkgs, packages, lib, ... }:
with lib;
let
  name = "sorgenfri";
  cfg = config.services.sorgenfri;
  opt = options.services.sorgenfri;
in {
  options.services.sorgenfri = {
    enable = mkEnableOption "Enables the Sorgenfri service.";

    package = mkOption {
      defaultText = lib.literalMD "`packages.default` from the foo flake";
    };

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

      script = ''
        export RELEASE_COOKIE=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
        exec ${cfg.package}/bin/${name} start;
      '';

    };

  };
}
