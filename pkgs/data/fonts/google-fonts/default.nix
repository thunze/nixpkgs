{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  installFonts,

  # passthru.updateScript
  _experimental-update-script-combinators,
  gitMinimal,
  nix,
  python3Packages,
  unstableGitUpdater,
  writers,
  writeShellScript,
}:

let
  fontsInfo = lib.importJSON ./fonts.json;

  normalizeName = name: lib.replaceString " " "-" (lib.toLower name);
  makeAttrName =
    name:
    let
      normalized = normalizeName name;
    in
    if builtins.match "^[[:digit:]].*" normalized != null then "_" + normalized else normalized;

  normalizeCategory = category: lib.replaceString "_" "-" (lib.toLower category);
  makeDescription =
    designer: category: "${lib.toSentenceCase (normalizeCategory category)} font by ${designer}";

  makeHomepage =
    name: minisite:
    if minisite != "" then
      minisite
    else
      "https://fonts.google.com/specimen/${lib.replaceString " " "+" name}";

  makeLicense =
    license:
    {
      APACHE2 = lib.licenses.asl20;
      OFL = lib.licenses.ofl;
      UFL = lib.licenses.ufl;
    }
    .${license};

  makeFont =
    {
      name,
      designer,
      minisite,
      category,
      license,
      path,
      ...
    }:
    stdenvNoCC.mkDerivation (finalAttrs: {
      pname = "google-fonts-${normalizeName name}";
      version = "0-unstable-2026-04-16";

      src = fetchFromGitHub {
        owner = "google";
        repo = "fonts";
        rev = "47831f08ec6d6d7ad6b465f23dc9f9a890a2a04b";
        hash = "sha256-T+rPBZ3ulW5dQqcVecm8XCY51gnGwD4QK5GHbNvv4Lc=";
      };

      # Setting `sourceRoot` instead would still copy the entire source to the
      # build directory, which can be slow due to its size.
      unpackCmd = ''
        cp -r "$src/${path}" .
      '';

      nativeBuildInputs = [ installFonts ];

      dontInstallFonts = true;
      doInstallCheck = true;

      installPhase = ''
        runHook preInstall

        installFont ttf $out/share/fonts/truetype/google-fonts/${normalizeName name}

        runHook postInstall
      '';

      # Check that fonts are present after installation
      installCheckPhase = ''
        runHook preInstallCheck

        ls -A $out/share/fonts/truetype/google-fonts/${normalizeName name}/*.ttf

        runHook postInstallCheck
      '';

      passthru = {
        updateScript = _experimental-update-script-combinators.sequence [
          # Update the version, commit hash, and source hash
          # Silence output to let the collect script determine the commit metadata
          {
            command = writeShellScript "google-fonts-update-script" ''
              ${lib.head (unstableGitUpdater { })} --hardcode-zero-version --shallow-clone > /dev/null
            '';
            supportedFeatures = [ "silent" ];
          }
          # Collect metadata about the available fonts and write it to `fonts.json`
          {
            command = writers.writePython3 "google-fonts-collect-script" {
              libraries = with python3Packages; [
                gftools
                protobuf
              ];
              makeWrapperArgs = [
                "--prefix"
                "PATH"
                ":"
                (lib.makeBinPath [
                  gitMinimal
                  nix
                ])
                "--set"
                "PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION"
                "python"
              ];
              doCheck = true;
            } ./collect.py;
            supportedFeatures = [ "commit" ];
          }
        ];
      };

      meta = {
        description = makeDescription designer category;
        homepage = makeHomepage name minisite;
        downloadPage = "https://github.com/google/fonts";
        license = makeLicense license;
        sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
        platforms = lib.platforms.all;
      };
    });

  googleFonts = lib.pipe fontsInfo [
    (map (font: lib.nameValuePair (makeAttrName font.name) (makeFont font)))
    builtins.listToAttrs
  ];
in

googleFonts
