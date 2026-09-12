{
  fetchFromGitHub,
  lib,
  nix-update-script,
  oo7,
  pkg-config,
  rustPlatform,
  testers,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "oo7";
  version = "0.6.0-unstable-2026-09-10";

  src = fetchFromGitHub {
    owner = "linux-credentials";
    repo = "oo7";
    rev = "3b9a14b35ae49e65af8af7ee2cbc80d984e5012b";
    hash = "sha256-fF+WLDWWDu7EOdeqk6Dw58vM/xfpo+Xyi2GX0fpm/UQ=";
  };

  # TODO: this won't cover tests from the client crate
  # Additionally cargo-credential will also not be built here
  buildAndTestSubdir = "cli";

  cargoHash = "sha256-XUEwk9xkyAZLu2DeriFTKf6TLn2eBYPritsrJ1c0xMs=";

  nativeBuildInputs = [ pkg-config ];

  passthru = {
    tests.testVersion = testers.testVersion { package = oo7; };

    updateScript = nix-update-script { };
  };

  meta = {
    description = "James Bond went on a new mission as a Secret Service provider";
    homepage = "https://github.com/linux-credentials/oo7";
    changelog = "https://github.com/linux-credentials/oo7/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      getchoo
      Scrumplex
    ];
    platforms = lib.platforms.linux;
    mainProgram = "oo7-cli";
  };
})
