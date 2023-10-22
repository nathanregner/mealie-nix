{ inputs, stdenv, ... }:
let inherit (inputs) crfpp;
in stdenv.mkDerivation {
  pname = "crf++";
  version = crfpp.rev;
  src = crfpp;
}

