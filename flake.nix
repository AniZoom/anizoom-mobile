{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    devenv.url = "github:cachix/devenv";
    flake-root.url = "github:srid/flake-root";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
        inputs.flake-root.flakeModule
      ];
      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem = { config, self', inputs', pkgs, system, lib, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowBroken = true;
              android_sdk.accept_license = true;
              allowUnfree = true;
            };
          };
        in
        let
          libraries = with pkgs; [
            webkitgtk
            gtk3
            cairo
            gdk-pixbuf
            glib-networking
            glib
            dbus
            openssl_3
            librsvg
            libxml2
          ];
          extraPackages = with pkgs; [
            cargo-tauri
            nodePackages.pnpm
          ];
          packages = (with pkgs;  [
            curl
            wget
            pkg-config
            dbus
            openssl_3
            glib
            glib-networking
            gtk3
            libsoup
            webkitgtk
            librsvg
          ]) ++ extraPackages;
          apple_sdk = with pkgs; [
            darwin.apple_sdk.frameworks.Foundation
            darwin.apple_sdk.frameworks.System
            darwin.apple_sdk.frameworks.Carbon
            darwin.apple_sdk.frameworks.Cocoa
            darwin.apple_sdk.frameworks.WebKit
          ];
          darwin_packages = apple_sdk ++ extraPackages;
          androidSdk = pkgs.androidenv.androidPkgs_9_0.androidsdk;
          androidComposition = pkgs.androidenv.composeAndroidPackages {
            cmdLineToolsVersion = "13.0";
            toolsVersion = "26.1.1";
            platformToolsVersion = "35.0.1";
            buildToolsVersions = [ "34.0.0" "30.0.3" ];
            includeEmulator = true;
            emulatorVersion = "35.1.4";
            platformVersions = [ "28" "29" "30" "33" ];
            includeSources = false;
            includeSystemImages = false;
            systemImageTypes = [ "google_apis_playstore" ];
            abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
            cmakeVersions = [ "3.10.2" ];
            includeNDK = true;
            ndkVersions = [ "26.3.11579264" ];
            useGoogleAPIs = false;
            useGoogleTVAddOns = false;
            includeExtras = [
              "extras;google;gcm"
            ];
          };
        in
        {
          devenv.shells.anizoom-mobile = {
            name = "anizoom-mobile";
            languages.rust = {
              enable = true;
              channel = "nightly";
              targets = [ "aarch64-linux-android" ];
            };
            packages = [
              androidComposition.androidsdk
              pkgs.rustup
              pkgs.android-studio
              pkgs.nodePackages.pnpm
              pkgs.jdk17
              pkgs.gradle
              pkgs.glibc
            ];
            env = rec {
              ANDROID_HOME = "${androidComposition.androidsdk}/libexec/android-sdk";
              NDK_HOME = "${ANDROID_HOME}/ndk-bundle";
              GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidComposition.androidsdk}/libexec/android-sdk/build-tools/34.0.0/aapt2";
              QT_QPA_PLATFORM = "wayland";
              LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath libraries}:$LD_LIBRARY_PATH";
            };
            enterShell =
              if (pkgs.stdenv.isDarwin) then ''
                echo $'\e[1;32mWelcom to anizoom project~\e[0m'
              '' else ''
              '';
          };
        };
    };
}
