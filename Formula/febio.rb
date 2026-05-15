class Febio < Formula
  desc "Nonlinear finite element solver for biomechanics"
  homepage "https://febio.org/"
  url "https://github.com/febiosoftware/FEBio/archive/refs/tags/v4.12.tar.gz"
  sha256 "4f21454e2c3c497c7cf85263b0eb080329039297eeb21265121ae67cdb4f64af"
  license "MIT"
  head "https://github.com/febiosoftware/FEBio.git", branch: "develop"

  depends_on "cmake" => :build
  depends_on "fftw"
  depends_on "hypre"
  depends_on "levmar"
  depends_on "libomp"
  depends_on "mmg"
  depends_on "nlopt"

  uses_from_macos "zlib"

  def install
    fftw = Formula["fftw"]
    hypre = Formula["hypre"]
    levmar_f = Formula["levmar"]
    libomp = Formula["libomp"]
    mmg = Formula["mmg"]
    nlopt = Formula["nlopt"]

    # FEBio's upstream macOS CI builds x86_64-only and uses Intel MKL for
    # both the Pardiso solver and OpenMP (via libiomp5). MKL is unavailable
    # on Apple Silicon, so MKL is off and FEBio falls back to the Skyline
    # linear solver. To keep OpenMP parallelism, we point USE_MKL_OMP at
    # Homebrew's libomp and let FEBio's existing OpenMP plumbing pick it up
    # — that machinery is what gates the `-Xpreprocessor -fopenmp` compile
    # flag on Apple.
    args = [
      "-DCMAKE_BUILD_TYPE=Release",
      "-DUSE_MKL=OFF",
      "-DUSE_FFTW=ON",
      "-DFFTW_INC=#{fftw.opt_include}",
      "-DFFTW_LIB=#{fftw.opt_lib}/libfftw3.dylib",
      "-DUSE_HYPRE=ON",
      "-DHYPRE_INC=#{hypre.opt_include}",
      "-DHYPRE_LIB=#{hypre.opt_lib}/libHYPRE.dylib",
      "-DUSE_LEVMAR=ON",
      "-DLEVMAR_INC=#{levmar_f.opt_include}",
      "-DLEVMAR_LIB=#{levmar_f.opt_lib}/liblevmar.a",
      "-DUSE_MMG=ON",
      "-DMMG_INC=#{mmg.opt_include}",
      "-DMMG_LIB=#{mmg.opt_lib}/libmmg3d.dylib",
      "-DMMGS_LIB=#{mmg.opt_lib}/libmmgs.dylib",
      "-DUSE_NLOPT=ON",
      "-DNLOPT_INC=#{nlopt.opt_include}",
      "-DNLOPT_LIB=#{nlopt.opt_lib}/libnlopt.dylib",
      "-DUSE_ZLIB=ON",
      "-DOMP_INC=#{libomp.opt_include}",
      "-DCMAKE_EXE_LINKER_FLAGS=-L#{libomp.opt_lib} -lomp",
      "-DCMAKE_SHARED_LINKER_FLAGS=-L#{libomp.opt_lib} -lomp",
    ]

    system "cmake", "-S", ".", "-B", "cbuild", *std_cmake_args, *args
    system "cmake", "--build", "cbuild"

    # FEBio's CMakeLists doesn't install anywhere by default. The binary
    # lands in cbuild/bin/febio4 and its shared libs in cbuild/lib/.
    bin.install "cbuild/bin/febio4"
    lib.install Dir["cbuild/lib/*.dylib"]

    # SDK: headers + libs so FEBioStudio (and other downstream consumers)
    # can link against this FEBio install via -DCMAKE_PREFIX_PATH=#{prefix}.
    # FEBio source uses #include <FEBioLib/version.h> etc., so headers go
    # directly under include/, not include/FEBio/.
    %w[FEBio FEBioFluid FEBioLib FEBioMech FEBioMix FEBioOpt FEBioPlot
       FEBioRVE FEBioXML FECore FEAMR FEBioTest FEImgLib NumCore].each do |mod|
      next unless File.directory?(mod)

      (include/mod).install Dir["#{mod}/*.h*"]
    end
    if File.exist?("FEBioConfig.cmake")
      (lib/"cmake/FEBio").mkpath
      cp "FEBioConfig.cmake", lib/"cmake/FEBio/"
    end
  end

  test do
    assert_path_exists bin/"febio4"
    # `-info` prints version then drops into FEBio's interactive prompt
    # waiting on stdin; closing stdin lets it exit cleanly with the banner
    # already emitted.
    output = shell_output("#{bin}/febio4 -info < /dev/null 2>&1")
    assert_match version.to_s, output
  end
end
