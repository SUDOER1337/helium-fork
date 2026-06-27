{
  description = "Helium browser development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    helium-src = {
      url = ".";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, helium-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        patchTools = with pkgs; [
          quilt
          python3
          python3Packages.httplib2
          python3Packages.six
          diffutils
          patchutils
        ];

        buildEnv = pkgs.buildFHSEnvBubblewrap {
          name = "helium-build";
          targetPkgs = p: with p; [
            gnumake cmake ninja pkg-config which perl rsync
            python3 nodejs git curl wget unzip gzip bzip2 xz
            bison flex gperf yasm nasm

            glib gtk3 pango cairo gdk-pixbuf
            atk at-spi2-atk at-spi2-core
            libdrm mesa wayland wayland-protocols libxkbcommon libepoxy
            dbus dbus-glib cups nss nspr
            alsa-lib pipewire libpulseaudio speexdsp

            zlib bzip2 lz4 zstd snappy
            flac libvpx libwebp
            libjpeg_turbo libpng libtiff
            expat libxml2 libxslt
            harfbuzz freetype fontconfig lcms2
            openssl krb5 libpcap
            libcap libuuid libffi elfutils
            glibc.static

            xorg.libX11 xorg.libXcomposite xorg.libXdamage
            xorg.libXext xorg.libXfixes xorg.libXi
            xorg.libXrandr xorg.libXrender xorg.libXScrnSaver
            xorg.libXtst xorg.libXcursor xorg.libxcb
          ];
          runScript = "${pkgs.bash}/bin/bash";
          profile = ''
            export HELIUM_SRC="${helium-src}"
            echo "=== Helium Build Environment ==="
            echo "Source: $HELIUM_SRC"
            echo ""
            echo "Workflow:"
            echo "  1. cd \$HELIUM_SRC"
            echo "  2. python3 utils/clone.py [--help]"
          '';
        };

      in {
        packages.default = buildEnv;

        devShells = {
          patch = pkgs.mkShell {
            name = "helium-patch";
            packages = patchTools;
            shellHook = ''
              export HELIUM_SRC="${helium-src}"
              echo "=== Helium Patch Development ==="
              echo "Source: $HELIUM_SRC"
              echo ""
              echo "  quilt push -a    # Apply all patches"
              echo "  quilt pop -a     # Remove all patches"
              echo "  quilt new foo    # Create a new patch"
              echo "  quilt refresh    # Refresh current patch"
              echo "  nix run .#       # Enter build FHS environment"
            '';
          };

          default = pkgs.mkShell {
            name = "helium-dev";
            packages = patchTools ++ [ pkgs.gn ];
            shellHook = ''
              export HELIUM_SRC="${helium-src}"
              echo "=== Helium Development Shell ==="
              echo "Source: $HELIUM_SRC"
              echo ""
              echo "  quilt push -a    # Apply all patches"
              echo "  nix run .#       # Enter FHS build environment"
            '';
          };
        };
      });
}
