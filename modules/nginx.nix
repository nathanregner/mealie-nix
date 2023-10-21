{ config, lib, modulesPath, mealie-nightly, ... }:
with lib;
let cfg = config.services.mealie;
in {
  options.services.mealie = {
    enable = mkEnableOption
      (lib.mdDoc "A self-hosted recipe manager and meal planner");

    package = mkOption {
      type = types.package;
      description = lib.mdDoc "Mealie package to be used in the module";
      default = mealie-nightly;
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

    hostName = mkOption {
      type = types.str;
      default = "localhost";
      description = lib.mdDoc "Hostname to serve Mealie on";
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

    nginx = mkOption {
      type = types.submodule
        (import "${modulesPath}/services/web-servers/nginx/vhost-options.nix" {
          inherit config lib;
        });
      default = { };
      example = literalExpression ''
        {
          serverAliases = [ "mealie.''${config.networking.domain}" ];
        }
      '';
      description =
        lib.mdDoc "Extra configuration for the nginx virtual host of mealie";
    };
  };

  config = mkIf cfg.enable {

    users.users = optionalAttrs (cfg.user == "mealie") {
      mealie = {
        group = cfg.group;
        isSystemUser = true;
        # TODO
        # uid = config.ids.uids.mealie;
      };
    };

    users.groups = optionalAttrs (cfg.group == "mealie") {
      # TODO
      # mealie.gid = config.ids.gids.mealie;
    };

    systemd.tmpfiles.rules =
      [ "d '${cfg.stateDir}' - ${cfg.user} ${cfg.group} - -" ]
      ++ lib.optional (cfg.configDir != null)
      "d '${cfg.configDir}' - ${cfg.user} ${cfg.group} - -";

    systemd.services.mealie = {
      description = "Moonraker, an API web server for Klipper";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ]
        ++ optional config.services.klipper.enable "klipper.service";

      environment = { DATA_DIR = cfg.stateDir; };

      script = ''
        exec ${cfg.package}/backend/bin/start
      '';

      serviceConfig = {
        WorkingDirectory = cfg.stateDir;
        PrivateTmp = true;
        Group = cfg.group;
        User = cfg.user;
      };
    };

    services.nginx = {
      enable = true;
      upstreams.mealie-apiserver.servers."${cfg.address}:${toString cfg.port}" =
        { };
      virtualHosts."${cfg.hostName}" = mkMerge [
        cfg.nginx
        {
          root = mkForce "${cfg.package}/frontend";
          locations = {
            "/" = {
              index = "index.html";
              tryFiles = "$uri $uri/ /index.html";
            };
            "/index.html".extraConfig = ''
              add_header Cache-Control "no-store, no-cache, must-revalidate";
            '';
            "/websocket" = {
              proxyWebsockets = true;
              proxyPass = "http://mealie-apiserver/websocket";
            };
          };
        }
      ];
    };
  };
}
