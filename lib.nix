{ pkgs ? import
    (fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-25.11")
    { config = { }; overlays = [ ]; }
}:

let
  lib = pkgs.lib;
  appName = "lahna";
  appVersion = lib.strings.fileContents ./VERSION;

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

  container = "";
in
{ shell = shell; package = package; container = container; }
