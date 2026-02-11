{
  description = "Pianoteq - Physically modelled virtual instrument";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Version configuration with all necessary metadata
      versions = {
        pianoteq7 = {
          version = "7.5.4";
          file = "pianoteq_linux_v754.7z";
          hash = "sha256-TA9CiuT21fQedlMUGz7bNNxYun5ArmRjvIxjOGqXDCs=";
          compression = "7z";
          majorVersion = "7";
          hasVst3 = false;
          hasLv2 = true;
        };
        pianoteq8 = {
          version = "8.4.3";
          file = "pianoteq_linux_v841.7z";
          hash = "sha256-72eV+d3jwRZJSs6I4e055ZrR/dvnhwAaM63eZEQAtOg=";
          compression = "7z";
          majorVersion = "8";
          hasVst3 = false;
          hasLv2 = true;
        };
        pianoteq9 = {
          version = "9.1.2";
          file = "pianoteq_setup_v911.tar.xz";
          hash = "sha256-Jvm/AhBwgj5INW8U48rJjgDB7j/Z1VnYKczvtrpl/AY=";
          compression = "tar.xz";
          majorVersion = "9";
          hasVst3 = true;
          hasLv2 = true;
        };
      };

      # Helper function to create Pianoteq packages with configurable features
      mkPianoteqPackage = { system, versionKey, enableStandalone ? true, enableVst3 ? true, enableLv2 ? false }:
        let
          pkgs = import nixpkgs {
            inherit system;
	    config.allowUnfree = true;
          };
          lib = pkgs.lib;
          versionConfig = versions.${versionKey};

          # Validate that requested components are available in this version
          validateComponents = lib.throwIf
            (enableVst3 && !versionConfig.hasVst3)
            "Pianoteq ${versionConfig.majorVersion} does not support VST3 plugin"
            (lib.throwIf
              (enableLv2 && !versionConfig.hasLv2)
              "Pianoteq ${versionConfig.majorVersion} does not support LV2 plugin"
              true);
        in
        pkgs.stdenv.mkDerivation rec {
          pname = "pianoteq${versionConfig.majorVersion}";
          inherit (versionConfig) version;

          # Use appropriate file name based on compression
          srcFile = versionConfig.file;

          icon = pkgs.fetchurl {
            name = "pianoteq_icon_128";
            url = "https://www.pianoteq.com/images/logo/pianoteq_icon_128.png";
            sha256 = "sha256-lO5kz2aIpJ108L9w2BHnRmq6wQP+6rF0lqifgor8xtM=";
          };

          src = pkgs.requireFile {
            name = srcFile;
            message = ''
              ┌─────────────────────────────────────────────────────────────────┐
              │  PIANOTEQ ${versionConfig.majorVersion} DOWNLOAD REQUIRED         │
              └─────────────────────────────────────────────────────────────────┘
            
              1️⃣  Download: ${srcFile}
                 From: https://www.modartt.com/download?file=${srcFile}
               
              2️⃣  Generate hash:
                   nix hash file --sri ./${srcFile}
                 
              3️⃣  Update hash in flake.nix:
                   Find the ${versionKey} entry and replace the hash
                 
              4️⃣  Add to nix store:
                   nix store add-file ./${srcFile}
            '';
            inherit (versionConfig) hash;
          };

          # Common library dependencies for autoPatchelfHook
          buildInputs = with pkgs; [
            alsa-lib
            freetype
            fontconfig
            xorg.libX11
            xorg.libXext
            stdenv.cc.cc.lib
            libjack2
            lv2
            libGL
          ];

          # Libraries loaded at runtime via dlopen()
          runtimeDependencies = with pkgs; [
            libGL
          ];

          # Compression-specific native build inputs
          nativeBuildInputs = with pkgs; [ autoPatchelfHook copyDesktopItems ] ++
            (if versionConfig.compression == "7z" then [ p7zip ]
            else if versionConfig.compression == "tar.xz" then [ xz ]
            else throw "Unsupported compression: ${versionConfig.compression}");

          # Compression-specific unpack command
          unpackCmd =
            if versionConfig.compression == "7z"
            then "7z x ${src}"
            else "tar xf ${src}";

          # Create desktop items only for standalone builds (adopted from official package)
          desktopItems = lib.optionals enableStandalone [
            (pkgs.makeDesktopItem {
              name = "pianoteq${versionConfig.majorVersion}";
              desktopName = "Pianoteq ${versionConfig.majorVersion}";
              exec = "pianoteq${versionConfig.majorVersion}";
              icon = "pianoteq_icon_128";
              comment = "Software synthesizer that features real-time MIDI-control of digital physically modeled pianos and related instruments";
              categories = [ "AudioVideo" "Audio" "Recorder" ];
              startupNotify = false;
              startupWMClass = "Pianoteq";
            })
          ];

          # Main build phase
          buildPhase = ''
            runHook preBuild
            # No build step for binary package
            runHook postBuild
          '';

          # Installation phase with conditional component installation
          installPhase = ''
            runHook preInstall

            ${lib.optionalString enableStandalone ''
              echo "Installing standalone application..."
              install -Dm 755 "x86-64bit/Pianoteq ${versionConfig.majorVersion}" "$out/bin/pianoteq${versionConfig.majorVersion}"
            ''}

            ${lib.optionalString (enableVst3 && versionConfig.hasVst3) ''
              echo "Installing VST3 plugin..."
              install -d "$out/lib/vst3/Pianoteq ${versionConfig.majorVersion}.vst3/Contents/x86_64-linux"
              install -Dm 755 "x86-64bit/Pianoteq ${versionConfig.majorVersion}.vst3/Contents/x86_64-linux/Pianoteq ${versionConfig.majorVersion}.so" \
                          "$out/lib/vst3/Pianoteq ${versionConfig.majorVersion}.vst3/Contents/x86_64-linux/Pianoteq ${versionConfig.majorVersion}.so"
              

            ''}

            ${lib.optionalString (enableLv2 && versionConfig.hasLv2) ''
              echo "Installing LV2 plugin..."
              install -Dm 755 "x86-64bit/Pianoteq ${versionConfig.majorVersion}.lv2/Pianoteq_${versionConfig.majorVersion}.so" \
                          "$out/lib/lv2/Pianoteq ${versionConfig.majorVersion}.lv2/Pianoteq_${versionConfig.majorVersion}.so"
              cd "x86-64bit/Pianoteq ${versionConfig.majorVersion}.lv2/"
              for i in *.ttl; do
                install -D "$i" "$out/lib/lv2/Pianoteq ${versionConfig.majorVersion}.lv2/$i"
              done
              cd ../..
            ''}

            runHook postInstall
          '';

          # Post-install for desktop integration (standalone only)
          postInstall = lib.optionalString enableStandalone ''
            install -Dm 444 ${icon} $out/share/icons/hicolor/128x128/apps/pianoteq_icon_128.png
          '';

          meta = with lib; {
            homepage = "https://www.modartt.com/";
            description = "Pianoteq ${versionConfig.majorVersion} - Physically modelled virtual instrument";
            longDescription = ''
              Pianoteq is a virtual instrument which in contrast to other virtual instruments 
              is physically modelled and thus can simulate the playability and complex behaviour 
              of real acoustic instruments. Because there are no samples, the file size is just 
              a tiny fraction of that required by other virtual instruments.
            '';
            license = licenses.unfree;
            platforms = [ "x86_64-linux" ];
            maintainers = [ "phga <phga@posteo.de>" ];
            sourceProvenance = with sourceTypes; [ binaryNativeCode ];
          };
        };

    in
    {
      packages = forAllSystems (system: {
        # Pianoteq 9 variants
        pianoteq9 = mkPianoteqPackage {
          inherit system;
          versionKey = "pianoteq9";
          enableStandalone = true;
          enableVst3 = true;
          enableLv2 = true;
        };

        pianoteq9-standalone = mkPianoteqPackage {
          inherit system;
          versionKey = "pianoteq9";
          enableStandalone = true;
          enableVst3 = false;
          enableLv2 = false;
        };

        pianoteq9-vst3 = mkPianoteqPackage {
          inherit system;
          versionKey = "pianoteq9";
          enableStandalone = false;
          enableVst3 = true;
          enableLv2 = false;
        };

        pianoteq9-lv2 = mkPianoteqPackage {
          inherit system;
          versionKey = "pianoteq9";
          enableStandalone = false;
          enableVst3 = false;
          enableLv2 = true;
        };

        # Pianoteq 8 variants (no VST3 support)
        pianoteq8 = mkPianoteqPackage {
          inherit system;
          versionKey = "pianoteq8";
          enableStandalone = true;
          enableVst3 = false; # Pianoteq 8 doesn't have VST3
          enableLv2 = true;
        };

        pianoteq8-standalone = mkPianoteqPackage {
          inherit system;
          versionKey = "pianoteq8";
          enableStandalone = true;
          enableVst3 = false;
          enableLv2 = false;
        };

        pianoteq8-lv2 = mkPianoteqPackage {
          inherit system;
          versionKey = "pianoteq8";
          enableStandalone = false;
          enableVst3 = false;
          enableLv2 = true;
        };

        # Pianoteq 7 variants (no VST3 support)
        pianoteq7 = mkPianoteqPackage {
          inherit system;
          versionKey = "pianoteq7";
          enableStandalone = true;
          enableVst3 = false; # Pianoteq 7 doesn't have VST3
          enableLv2 = true;
        };

        pianoteq7-standalone = mkPianoteqPackage {
          inherit system;
          versionKey = "pianoteq7";
          enableStandalone = true;
          enableVst3 = false;
          enableLv2 = false;
        };

        pianoteq7-lv2 = mkPianoteqPackage {
          inherit system;
          versionKey = "pianoteq7";
          enableStandalone = false;
          enableVst3 = false;
          enableLv2 = true;
        };

        # Default package (latest version - full)
        default = self.packages.${system}.pianoteq9;
      });

      # Development shell for easier maintenance
      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          buildInputs = with nixpkgs.legacyPackages.${system}; [
            nixpkgs-fmt
          ];
        };
      });

      # Formatter for nix files
      formatter = forAllSystems (system:
        nixpkgs.legacyPackages.${system}.nixpkgs-fmt
      );
    };
}
