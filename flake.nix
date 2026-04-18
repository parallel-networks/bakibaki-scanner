{
  description = "PNL Bakibaki APK Server";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }: let
    forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
  in {
    packages = forAllSystems (system: {
      default = nixpkgs.legacyPackages.${system}.runCommand "bakibaki-apk-public" {} ''
        mkdir -p $out
        cp -r ${./public}/* $out/
      '';
    });

    nixosModules.default = { config, lib, pkgs, ... }:
      with lib;
      let
        cfg = config.services.bakibaki-apk-server;
        publicFiles = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      in {
        options.services.bakibaki-apk-server = {
          enable = mkEnableOption "PNL Bakibaki APK Server";
          port = mkOption {
            type = types.port;
            default = 80;
            description = "Port to listen on.";
          };
        };

        config = mkIf cfg.enable {
          services.nginx = {
            enable = true;
            virtualHosts."bakibaki-apk" = {
              listen = [{ addr = "0.0.0.0"; port = cfg.port; }];
              root = "${publicFiles}";
              locations."/".extraConfig = ''
                autoindex on;
              '';
            };
          };
          networking.firewall.allowedTCPPorts = [ cfg.port ];
        };
      };
  };
}
