{ pkgs ? import
    (fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-25.11")
    { config = { }; overlays = [ ]; }
}:

let
  lib = pkgs.lib;
  appName = "lahna";
  appVersion = lib.strings.fileContents ./VERSION;
  appPort = 8152;

  luaEnv = pkgs.luajit.withPackages (ps: with ps; [
    luarocks
    http
  ]);

  dependencies = with pkgs; [
    wget
    nixpkgs-fmt
    pandoc
  ];

  luaLightWings = {
    url = "https://raw.githubusercontent.com/burij/"
      + "lua-light-wings/refs/tags/v.0.4/modules/lua-light-wings.lua";
    sha256 = "sha256-Tczj+XNIobX64Cncm0/rbDwMizUDhRmeyjFwrJrDCco=";
  };

  shell = pkgs.mkShell {
    buildInputs = [ luaEnv dependencies ];
    shellHook = ''
      # export LUAOS="./conf.lua"
      alias run='lua main.lua'
      alias lahna='./result/bin/lahna'
      alias form='nixpkgs-fmt lib.nix'
      mkdir modules

      cp ${pkgs.fetchurl luaLightWings} ./modules/lua-light-wings.lua

    '';
  };

  package = pkgs.stdenv.mkDerivation {
    pname = appName;
    version = appVersion;

    src = ./.;

    # src = pkgs.fetchFromGitHub {
    #   owner = "burij";
    #   repo = appName;
    #   rev = appVersion;
    #   sha256 = "";
    # };

    extraFile = pkgs.fetchurl luaLightWings;

    nativeBuildInputs = [ pkgs.makeWrapper ];
    buildInputs = [ luaEnv dependencies ];

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/lib
      cp -r . $out/lib/$pname
      cp -r ./modules/* $out/lib/$pname/
      cp $extraFile $out/lib/$pname/lua-light-wings.lua

      makeWrapper ${luaEnv}/bin/luarocks $out/bin/luarocks
      makeWrapper ${luaEnv}/bin/luajit $out/bin/$pname \
        --add-flags "$out/lib/$pname/main.lua" \
        --set LUA_PATH "$out/lib/$pname/?.lua;$out/lib/$pname/?/init.lua;" \
        --set LUA_CPATH "${luaEnv}/lib/lua/${luaEnv.lua.luaversion}/?.so" \
        --prefix PATH : ${pkgs.pandoc}/bin

      # Additional custom wrapper
      cat > $out/bin/$pname-extra <<EOF
      #!${pkgs.stdenv.shell}
      exec ${luaEnv}/bin/lua "$out/lib/$pname/main.lua" "\$@"
      EOF
      chmod +x $out/bin/$pname-extra

    '';

    meta = with pkgs.lib; {
      description = "Lahna";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };

  container = { config, lib, pkgs, ... }: {
    containers.${appName} = {
      autoStart = true;
      privateNetwork = false;
      privateUsers = "no";
      hostAddress = "10.0.0.1";
      localAddress = "10.0.0.2";

      bindMounts = {
        "${appName}-public" = {
          hostPath = "/srv/config/${appName}/public";
          mountPoint = "/var/lib/${appName}/public";
          isReadOnly = false;
        };
        "${appName}-conf" = {
          hostPath = "/srv/config/${appName}/conf.lua";
          mountPoint = "/var/lib/${appName}/conf.lua";
          isReadOnly = false;
        };
      };

      config = { config, pkgs, ... }: {
        system.stateVersion = "25.11";

        environment.systemPackages = with pkgs; [
          package
        ];

        systemd.services."${appName}" = {
          description = "${appName}-daemon";
          after = [ "network.target" ];
          environment = {
            LAHNA_HOST = "0.0.0.0";
            LAHNA_PORT = "${toString appPort}";
          };
          serviceConfig = {
            Type = "simple";
            ExecStart = "${package}/bin/${appName} /var/lib/${appName}/conf.lua";
            Restart = "always";
            RestartSec = 10;
            StandardOutput = "journal";
            StandardError = "journal";
            WorkingDirectory = "${package}/lib/${appName}";
          };
          wantedBy = [ "multi-user.target" ];
        };

        users.users.${appName} = {
          isSystemUser = true;
          group = appName;
        };
        users.groups.${appName} = { };

        networking.firewall.allowedTCPPorts = [ appPort ];
      };
    };
  };

in
{ shell = shell; package = package; container = container; }
