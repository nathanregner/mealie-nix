{ modulesPath, config, lib, pkgs, ... }:
with lib;
let cfg = config.services.mealie;
in {
  options.services.mealie = {
    enable = mkEnableOption
      (lib.mdDoc "A self-hosted recipe manager and meal planner");

    package = mkOption {
      type = types.package;
      description = lib.mdDoc "Mealie package to be used in the module";
      default = pkgs.mainsail;
    };

    hostName = mkOption {
      type = types.str;
      default = "localhost";
      description = lib.mdDoc "Hostname to serve Mealie on";
    };

    nginx = mkOption {
      type = types.submodule
        (import "${modulesPath/services/web-servers/nginx/vhost-options.nix}" {
          inherit config lib;
        });
      default = { };
      example = literalExpression ''
        {
          serverAliases = [ "mealie.''${config.networking.domain}" ];
        }
      '';
      description =
        lib.mdDoc "Extra configuration for the nginx virtual host of Mealie.";
    };
  };

  config = mkIf cfg.enable {
    services.nginx = {
      enable = true;
      upstreams.mealie-apiserver.servers."${cfg.address}:${toString cfg.port}" =
        { };
      virtualHosts."${cfg.hostName}" = mkMerge [
        cfg.nginx
        {
          root = mkForce "${cfg.package}/static/";
          locations = {
            "/" = {
              index = "index.html";
              tryFiles = "$uri $uri/ /index.html";
            };
            "/index.html".extraConfig = ''
              add_header Cache-Control "no-store, no-cache, must-revalidate";
            '';
            "/api" = {
              proxyWebsockets = true;
              proxyPass = "http://mealie-apiserver/websocket";
            };
          };
        }
      ];
    };
  };
}
