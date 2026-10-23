{ pkgs, lib, uv2nix, pyproject-nix, pyproject-build-systems }:
rec {
  python = pkgs.python3;

  workspace = uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = ../.;
  };

  uvLockedOverlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  pythonSet = (pkgs.callPackage pyproject-nix.build.packages { inherit python; }).overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.default
      uvLockedOverlay
    ]
  );

  editableOverlay = workspace.mkEditablePyprojectOverlay {
    root = "$REPO_ROOT";
    members = [ "shwim" ];
  };

  editablePythonSet = pythonSet.overrideScope editableOverlay;

  devPythonEnv = editablePythonSet.mkVirtualEnv "shwim-dev-env" workspace.deps.all;

  appPythonEnv = pythonSet.mkVirtualEnv (pythonSet.shwim.pname + "-env") workspace.deps.default;
}
