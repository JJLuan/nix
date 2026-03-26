{ config, pkgs, ... }:

{
  networking = {
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Enable networking
    networkmanager.enable = true;
    hostId = "cafef00d";
    hostName = "nixos"; # Define your hostname.
    useDHCP = false;


    vlans = {
      # IOT VLAN
      vlan10 = {id=10; interface="enp1s0"; };
    };

    interfaces.enp1s0.useDHCP = false;

    bridges.br0.interfaces = ["enp1s0"];
    interfaces.br0 = {
      useDHCP = true;
    };

    interfaces.vlan10.useDHCP = false;
    bridges.br1.interfaces = ["vlan10"];
    interfaces.br1 = {
      useDHCP = true;
    };

    # Open ports in the firewall.
    # networking.firewall.allowedTCPPorts = [ ... ];
    # networking.firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    firewall.enable = false;
  };
}
