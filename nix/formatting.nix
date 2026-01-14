{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];
  perSystem =
    { pkgs, lib, ... }:
    {
      treefmt = {
        # Python
        programs.ruff.format = true;
        programs.ruff.check = true;
        # Nix
        programs.nixpkgs-fmt.enable = true;
      };
    };
}
