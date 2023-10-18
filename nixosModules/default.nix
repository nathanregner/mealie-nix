{ config, lib, pkgs, ... }:
with lib;
let cfg = config.services.mealie;
in {
  options.services.mealie = {
    enable = mkEnableOption
      (lib.mdDoc "A self-hosted recipe manager and meal planner");

    package = mkOption {
      type = types.package;
      description = lib.mdDoc "Mealie package to be used in the module";
      default = pkgs.mealie;
    };

    stateDir = mkOption {
      type = types.path;
      default = "/var/lib/mealie";
      description = lib.mdDoc "Mealie data directory";
    };

    user = mkOption {
      type = types.str;
      default = "mealie";
      description = lib.mdDoc "User account under which Mealie runs";
    };

    group = mkOption {
      type = types.str;
      default = "mealie";
      description = lib.mdDoc "Group account under which Mealie runs";
    };

    address = mkOption {
      type = types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = lib.mdDoc "The IP or host to listen on";
    };

    port = mkOption {
      type = types.ints.unsigned;
      default = 9000;
      description = lib.mdDoc "The port to listen on";
    };
  };

  config = mkIf cfg.enable {
    users.users = optionalAttrs (cfg.user == "mealie") {
      mealie = {
        group = cfg.group;
        isSystemUser = true;
      };
    };

    users.groups = optionalAttrs (cfg.group == "mealie") { mealie = { }; };

    systemd.tmpfiles.rules =
      [ "d '${cfg.stateDir}' - ${cfg.user} ${cfg.group} - -" ];

    systemd.services.mealie = {
      description = "A self-hosted recipe manager and meal planner";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        DATA_DIR = cfg.stateDir;
        PRODUCTION = "True";
        STATIC_FILES = "${cfg.package}/spa/static";
      };

      script = ''
        ${cfg.package}/bin/uvicorn mealie.app:app --host ${cfg.address} --port ${
          toString cfg.port
        }
      '';

      serviceConfig = {
        WorkingDirectory = cfg.stateDir;
        PrivateTmp = true;
        Group = cfg.group;
        User = cfg.user;
      };
    };
  };
}
