{ config, pkgs, ... }:
{
  systemd.services.create-ts-network = {
    serviceConfig.Type = "oneshot";
    wantedBy = [ "podman-newt.service" "podman-teamspeak6-server.service" ];
    script = ''
      ${pkgs.podman}/bin/podman network exists ts_bridge || \
      ${pkgs.podman}/bin/podman network create ts_bridge
    '';
  };

  virtualisation.oci-containers = {
    backend="podman";
    containers ={
      "teamspeak6-server" = {
        image = "teamspeaksystems/teamspeak6-server:latest";

        # Ports: Note the /udp suffix for the voice port
        ports = [
          "9987:9987/udp"   # Voice
          "30033:30033/tcp" # File Transfer
          #"10080:10080/tcp" #Web Query
        ];

        # Environment variables
        environment = {
          TSSERVER_LICENSE_ACCEPTED = "accept";
        };

        # Volumes: Mapping a host path to the container path
        volumes = [
          "/var/lib/teamspeak:/var/tsserver"
        ];

        # Equivalent to 'unless-stopped' in the systemd context
        autoStart = true;
        extraOptions = ["--network=ts_bridge"];
      };

      newt = {
        image = "fosrl/newt:latest";
        volumes = ["/var/run/podman/podman.sock:/var/run/docker.sock:ro"];
        environment = {
          PANGOLIN_ENDPOINT = "https://pangolin.chocomintpie.com";
          NEWT_ID = "c4ubk9q7ywe2ncf";
          NEWT_SECRET = "";
        };
        extraOptions = ["--network=ts_bridge"];
        dependsOn = ["teamspeak6-server"];
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/teamspeak 0755 9987 9987 -"
  ];
}
