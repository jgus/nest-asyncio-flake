{
  description = "nest-asyncio: versioned Python package with corrected distribution metadata.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-lib = {
      url = "github:jgus/flake-lib/v1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { nixpkgs, flake-utils, flake-lib, ... }:
    let
      pin = import ./pin.nix;
      inherit (pin) version hash;
      source = { type = "pypi"; pname = "nest_asyncio"; format = "sdist"; };
      overlay = final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (pyfinal: pyprev: {
            nest-asyncio = pyprev.nest-asyncio.overridePythonAttrs (_: {
              inherit version;
              SETUPTOOLS_SCM_PRETEND_VERSION = version;
              postPatch = null;
              src = pyfinal.fetchPypi { inherit version hash; pname = "nest_asyncio"; };
            });
          })
        ];
      };
    in
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in
        {
          packages = {
            nest-asyncio = pkgs.python3.pkgs.nest-asyncio;
            default = pkgs.python3.pkgs.nest-asyncio;
            update-version = flake-lib.lib.mkUpdateVersion { inherit pkgs source; buildAttr = "nest-asyncio"; };
            update-branches = flake-lib.lib.mkUpdateBranches { inherit pkgs source; pinSchema = "pypi"; };
          };
        }) // {
      overlays.default = overlay;
    };
}
