# GH_ADMIN_TOKEN=$(gh auth token) pin-github-action .github/workflows/build.yml
{ buildNpmPackage, fetchFromGitHub }:
buildNpmPackage rec {
  pname = src.repo;
  version = src.rev;

  # https://github.com/mheap/pin-github-action
  src = fetchFromGitHub {
    owner = "mheap";
    repo = "pin-github-action";
    rev = "8e271c1eb28e643569f502d4df589ce5d77add4e";
    hash = "sha256-FBNdK+d1gXvC7uxARZrM7RHdwiPX/Vi1bp84R78t6wI=";
  };

  npmDepsHash = "sha256-UTOPQSQwZZ9U940zz8z4S/eAO9yPX4c1nsTXTlwlUfc=";

  NODE_OPTIONS = "--openssl-legacy-provider";
  dontNpmBuild = true;
}
