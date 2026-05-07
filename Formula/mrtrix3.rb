class Mrtrix3 < Formula
  desc "Tools for diffusion MRI analysis"
  homepage "https://www.mrtrix.org"
  url "https://github.com/MRtrix3/mrtrix3/archive/refs/tags/3.0.8.tar.gz"
  sha256 "9c694934781c287c51a0d35ad5d7687b529e5c04e3b2ac0985599b0c48644721"
  license "MPL-2.0"

  depends_on "python@3.13" => :build
  depends_on "eigen@3"
  depends_on "fftw"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "zlib"

  def install
    eigen = Formula["eigen@3"]
    ENV["EIGEN_CFLAGS"] = "-isystem #{eigen.opt_include}/eigen3"

    python3 = Formula["python@3.13"].opt_bin/"python3.13"
    system python3, "configure", "-nogui"
    system python3, "build"

    # Install binaries and libraries
    bin.install Dir["bin/*"]
    lib.install Dir["lib/*.dylib"]

    # Install the MRtrix shared data
    (share/"mrtrix3").install "share/mrtrix3/labelconvert"
  end

  test do
    assert_match "mrconvert", shell_output("#{bin}/mrconvert --version 2>&1")
  end
end
