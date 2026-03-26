# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let 
  zwaveXml = pkgs.writeText "zwave_dongle.xml" ''
    <hostdev mode='subsystem' type='usb' managed='yes'>
      <source>
        <vendor id='0x1a86'/>
        <product id='0x55d4'/>
      </source>
    </hostdev>
  '';

  zwaveAttachScript = pkgs.writeShellScript "zwave-attach" ''
    # Silence errors during detach in case the ghost doesn't exist
    ${pkgs.libvirt}/bin/virsh --connect qemu:///system detach-device haos ${zwaveXml} --live 2>/dev/null
    ${pkgs.coreutils}/bin/sleep 2
    ${pkgs.libvirt}/bin/virsh --connect qemu:///system attach-device haos ${zwaveXml} --live 
  '';
in
  {
    imports =
      [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./networking.nix
      ./teamspeak.nix
    ];

  # flakes
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;
  services.xserver.autorun = false;
  services.xserver.displayManager.startx.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  # services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Intel Iris graphics
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      vpl-gpu-rt
    ];
  };

  # tmux
  programs.tmux = {
    enable = true;
    clock24 = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.john = {
    isNormalUser = true;
    description = "John";
    extraGroups = [ "networkmanager" "wheel" "libvirtd"];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
  ];
};

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };

  programs.git.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    pkgs.gcc
    pkgs.home-manager
    pkgs.nix-search-cli
    pkgs.wezterm
    pkgs.wl-clipboard
    pkgs.xz
    pkgs.virt-manager
    virt-viewer
    bind
    htop
    pkgs.usbutils
    python315
    jdk21_headless
    unzip
    #vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
];

  # Virtualization
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  virtualisation.podman.enable=true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  #qemu guest agent
  services.qemuGuest.enable = true;

  #force a 'replug' of the zwave dongle to clear it from the host
  systemd.services.zooz-hotplug = {
  description = "Force Hotplug of Zooz 800 Z-Wave Stick to HAOS";
  after = [ "libvirtd.service" ];
  wants = [ "libvirtd.service" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    # Wait 45 seconds for HAOS to actually start its internal USB bus
    ExecStartPre = "${pkgs.coreutils}/bin/sleep 45"; 
    ExecStart = ''
      ${pkgs.bash}/bin/bash -c " \
        ${pkgs.libvirt}/bin/virsh detach-device haos ${zwaveXml} --live || true; \
        ${pkgs.coreutils}/bin/sleep 2; \
        ${pkgs.libvirt}/bin/virsh attach-device haos ${zwaveXml} --live \
        "
    '';
  };
};

  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
