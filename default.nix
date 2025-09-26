{ pkgs ? import <nixpkgs> { } }:

let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-25.05";
  pkgs = import nixpkgs { config = { }; overlays = [ ]; };

  appName = "lahna";
  appVersion = "0.1";

  luaEnv = pkgs.luajit.withPackages (ps: with ps; [
    luarocks
    http
  ]);

  dependencies = with pkgs; [
    wget
    nixpkgs-fmt
    pandoc
  ];

  shell = pkgs.mkShell {
    buildInputs = [ luaEnv dependencies ];
    shellHook = ''
      # export LUAOS="./conf.lua"
      alias run='lua main.lua'
      alias lahna='./result/bin/lahna'
      alias build='nix-build -A package'
      alias make='rm result;git add .;build;git commit -m '
      mkdir modules

      cp ${pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/burij/"
          +"lua-light-wings/refs/tags/v.0.3.1/modules/lua-light-wings.lua";
        sha256 = "sha256-3RBZDxmSOXNJ+rpBG/VmXSajTRsvVU2y8zKsxqDw4JA=";
      }} ./modules/lua-light-wings.lua

      nixpkgs-fmt default.nix
    '';
  };

  package = pkgs.stdenv.mkDerivation {
    pname = appName;
    version = appVersion;

    # src = ./.;

    src = pkgs.fetchFromGitHub {
      owner = "burij";
      repo = appName;
      rev = appVersion;
      sha256 = "sha256-Z2iJotdJSXS3lg+O8sazqvNpfbfCUxH7dmcV9VwTU5M=";
    };

    extraFile = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/burij/"
        + "lua-light-wings/refs/tags/v.0.3.1/modules/lua-light-wings.lua";
      sha256 = "sha256-3RBZDxmSOXNJ+rpBG/VmXSajTRsvVU2y8zKsxqDw4JA=";
    };

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
in
{ shell = shell; package = package; }
