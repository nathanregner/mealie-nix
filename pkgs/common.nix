{ src, lib }: {
  version = src.rev;
  meta = with lib; {
    homepage = "https://nightly.mealie.io/";
    license = licenses.agpl3Only;
  };
}
