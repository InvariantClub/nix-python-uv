{ inputs, ... }:
with inputs; {
  perSystem =
    { lib
    , system
    , ...
    }:
    let
      pkgs = import nixpkgs { inherit system; };

      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ../.; };

      overlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };

      editableOverlay = workspace.mkEditablePyprojectOverlay {
        root = "$REPO_ROOT";
      };

      pythonSets =
        let
          # Get the Python version from the ./.python-version file.
          version = lib.replaceString "." "" (lib.trim (builtins.readFile ../.python-version));
          python = pkgs."python${version}";
        in
        (pkgs.callPackage pyproject-nix.build.packages {
          inherit python;
        }).overrideScope
          (
            lib.composeManyExtensions [
              pyproject-build-systems.overlays.wheel
              overlay
              (
                final: prev:
                  let
                    inherit (final) resolveBuildSystem;
                    inherit (builtins) mapAttrs;
                    buildSystemOverrides = {
                      # Note: If there's a missing setuptools dependency in
                      # package pyabc you write:
                      #
                      # pyabc.setuptools = [];
                      #
                      # here.
                    };
                  in
                  mapAttrs
                    (
                      name: spec:
                        prev.${name}.overrideAttrs (old: {
                          nativeBuildInputs = old.nativeBuildInputs ++ resolveBuildSystem spec;
                        })
                    )
                    buildSystemOverrides
              )
            ]
          );

      pythonSet = pythonSets.overrideScope editableOverlay;
      virtualenv = pythonSet.mkVirtualEnv "dev-venv" workspace.deps.all;

      addMeta = p: drv:
        drv.overrideAttrs (old: {
          passthru = lib.recursiveUpdate (old.passthru or { }) {
            inherit (pythonSet.testing.passthru) tests;
          };

          meta =
            (old.meta or { })
            // {
              # Corresponds to the [script] entrypoint
              mainProgram = p;
            };
        });
    in
    {
      packages = rec {
        hello = addMeta "hello" (pythonSet.mkVirtualEnv "hello-venv" workspace.deps.default);
        other = addMeta "other" (pythonSet.mkVirtualEnv "other-venv" workspace.deps.default);
        default = hello;
      };


      checks = {
        test = pkgs.runCommand "test"
          {
            buildInputs = [ virtualenv ];
          } ''
          pytest -p no:cacheprovider -m pure ${ lib.cleanSource ../. } && \
            touch $out
        '';
      };


      devShells = {
        default = pkgs.mkShell {
          packages = [
            virtualenv
            pkgs.uv
            pkgs.ruff
          ];
          env = {
            UV_NO_SYNC = "1";
            UV_PYTHON = pythonSet.python.interpreter;
            UV_PYTHON_DOWNLOADS = "never";
          };
          shellHook = ''
            unset PYTHONPATH
            export REPO_ROOT=$(git rev-parse --show-toplevel)
          '';
        };
      };
    };
}
