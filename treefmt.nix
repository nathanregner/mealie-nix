{ pkgs }:
{
  projectRootFile = "flake.nix";
  # https://github.com/numtide/treefmt-nix?tab=readme-ov-file#supported-programs
  programs = {
    nixfmt-rfc-style.enable = true;
    prettier.enable = true;
  };
}
