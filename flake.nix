{
  description = "Peer-to-peer terminal sharing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , uv2nix
    , pyproject-nix
    , pyproject-build-systems
    , git-hooks
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs.callPackage ./nix {
          inherit uv2nix pyproject-nix pyproject-build-systems;

        })
          pythonSet
          devPythonEnv
          appPythonEnv;
      in
      {
        checks =
          {
            pre-commit-check = git-hooks.lib.${system}.run {
              src = ./.;
              hooks.nixpkgs-fmt.enable = true;
            };
          };

        devShells.default =
          let
            inherit (self.checks.${system}.pre-commit-check) shellHook enabledPackages;
          in
          pkgs.mkShell {
            shellHook = ''
              ${shellHook}
              unset PYTHONPATH
            '';
            buildInputs = enabledPackages;

            packages = [
              devPythonEnv
            ]
            ++ (with pkgs; [
              uv
              pre-commit
              nixfmt
            ]);
            env.REPO_ROOT = toString ./.;
          };

        packages.wheel = pythonSet.shwim.override {
          pyprojectHook = pythonSet.pyprojectDistHook;
        };

        packages.default =
          let
            util = pkgs.callPackages pyproject-nix.build.util { };
            shwimApp = util.mkApplication {
              venv = appPythonEnv;
              package = pythonSet.shwim;
            };
          in
          shwimApp;
      }
    );
}
