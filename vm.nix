{
  name = "service-startup";

  nodes.machine = { outputs, pkgs, lib, ... }: {
    imports = [ outputs.nixosModules.default ];
    nixpkgs.overlays = [ outputs.overlays.default ];
    services.mealie-nightly.enable = true;
  };

  testScript = ''
    machine.start()

    machine.wait_for_unit("mealie-nightly.service")
    machine.wait_until_succeeds("curl http://localhost:9000/api/app/about", timeout=30)
  '';
}

