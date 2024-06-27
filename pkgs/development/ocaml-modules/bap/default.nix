{ lib, stdenv, fetchFromGitHub, fetchurl, fetchpatch
, ocaml, findlib, ocamlbuild, ocaml_oasis
, bitstring, camlzip, cmdliner, core_kernel, ezjsonm, fileutils, mmap, lwt, ocamlgraph, ocurl, re, uri, zarith, piqi, piqi-ocaml, uuidm, llvm, frontc, ounit, ppx_jane, parsexp
, utop, libxml2, ncurses
, linenoise
, ppx_bap
, ppx_bitstring
, yojson
, which, makeWrapper, writeText
, z3
}:

if lib.versionOlder ocaml.version "4.08"
then throw "BAP is not available for OCaml ${ocaml.version}"
else

stdenv.mkDerivation (self: {
  pname = "ocaml${ocaml.version}-bap";
  version = "2.5.0-unstable-2024-04-25";
  src = fetchFromGitHub {
    owner = "BinaryAnalysisPlatform";
    repo = "bap";
    rev = "95e81738c440fbc928a627e4b5ab3cccfded66e2";
    hash = "sha256-gogcwqK7EK4Fs4HiCXKxWeFpJ1vJlJupMtJu+8M9kjs=";
  };

  sigs = fetchurl {
    # sigs.zip has not been correctly built since 2.4.0
    url = "https://github.com/BinaryAnalysisPlatform/bap/releases/download/v2.4.0/sigs.zip";
    sha256 = "sha256-k0fKblZgDRmtwAlq9rRxZVZYY5GTJExfJeaRj0STyTQ=sha256-k0fKblZgDRmtwAlq9rRxZVZYY5GTJExfJeaRj0STyTQ=";
  };

  createFindlibDestdir = true;

  setupHook = writeText "setupHook.sh" ''
    export CAML_LD_LIBRARY_PATH="''${CAML_LD_LIBRARY_PATH-}''${CAML_LD_LIBRARY_PATH:+:}''$1/lib/ocaml/${ocaml.version}/site-lib/${self.pname}-${self.version}/"
    export CAML_LD_LIBRARY_PATH="''${CAML_LD_LIBRARY_PATH-}''${CAML_LD_LIBRARY_PATH:+:}''$1/lib/ocaml/${ocaml.version}/site-lib/${self.pname}-${self.version}-llvm-plugins/"
  '';

  nativeBuildInputs = [ which makeWrapper ocaml findlib ocamlbuild ocaml_oasis ];

  buildInputs = [ ocamlbuild
                  linenoise
                  ounit
                  ppx_bitstring
                  z3
                  utop libxml2 ncurses ];

  propagatedBuildInputs = [ bitstring camlzip cmdliner ppx_bap core_kernel ezjsonm fileutils mmap lwt ocamlgraph ocurl re uri zarith piqi parsexp
                            piqi-ocaml uuidm frontc yojson ];

  installPhase = ''
    runHook preInstall
    export OCAMLPATH=$OCAMLPATH:$OCAMLFIND_DESTDIR;
    export PATH=$PATH:$out/bin
    export CAML_LD_LIBRARY_PATH=''${CAML_LD_LIBRARY_PATH-}''${CAML_LD_LIBRARY_PATH:+:}$OCAMLFIND_DESTDIR/bap-plugin-llvm/:$OCAMLFIND_DESTDIR/bap/
    mkdir -p $out/lib/bap
    make install
    mv $out/bin/baptop $out/bin/baptop0
    makeWrapper ${utop}/bin/utop $out/bin/baptop --prefix OCAMLPATH : $OCAMLPATH --prefix CAML_LD_LIBRARY_PATH : $CAML_LD_LIBRARY_PATH \
      --prefix PATH : $PATH --add-flags "-ppx ppx-bap -short-paths -require \"bap.top\""
    wrapProgram $out/bin/bapbuild --prefix OCAMLPATH : $OCAMLPATH --prefix PATH : $PATH
    ln -s $sigs $out/share/bap/sigs.zip
    runHook postInstall
  '';

  disableIda = "--disable-ida";
  disableGhidra = "--disable-ghidra";

  patches = [ ];

  preConfigure = ''
    substituteInPlace oasis/llvm --replace-fail -lcurses -lncurses
  '';

  configureFlags = [ "--enable-everything ${self.disableIda} ${self.disableGhidra}" "--with-llvm-config=${llvm.dev}/bin/llvm-config" ];

  meta = with lib; {
    description = "Platform for binary analysis. It is written in OCaml, but can be used from other languages.";
    homepage = "https://github.com/BinaryAnalysisPlatform/bap/";
    license = licenses.mit;
    maintainers = with maintainers; [ maurer katrinafyi ];
    mainProgram = "bap";
  };
})
