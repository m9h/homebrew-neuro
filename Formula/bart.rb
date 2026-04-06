class Bart < Formula
  desc "Berkeley Advanced Reconstruction Toolbox for MRI"
  homepage "https://mrirecon.github.io/bart/"
  url "https://github.com/mrirecon/bart/archive/refs/tags/v1.0.00.tar.gz"
  sha256 "cf8ae4ba5d8152d269b059342e57df4e4a303cae15a122095141d69fddeaf9df"
  license "BSD-3-Clause"

  depends_on "gcc" => :build
  depends_on "make" => :build
  depends_on "fftw"
  depends_on "libpng"
  depends_on "openblas"

  def install
    openblas = Formula["openblas"]
    fftw = Formula["fftw"]
    libpng = Formula["libpng"]
    gcc = Formula["gcc"]
    gcc_major = gcc.version.major

    # Patch: replace cblas_openblas.h include with cblas.h (brew vs MacPorts)
    system "find", "src", "-name", "*.c", "-o", "-name", "*.h",
           "-exec", "sed", "-i", "", "s/cblas_openblas.h/cblas.h/g", "{}", ";"

    # Patch: replace MacPorts /opt/local paths with brew paths
    inreplace "Makefile" do |s|
      s.gsub! "/opt/local/", "#{HOMEBREW_PREFIX}/"
    end

    ENV["CC"] = "#{gcc.opt_bin}/gcc-#{gcc_major}"
    ENV.append "CPPFLAGS", "-I#{libpng.opt_include}"
    ENV.append "LDFLAGS", "-L#{libpng.opt_lib}"
    system "gmake", "-j#{ENV.make_jobs}",
           "MACPORTS=1",
           "BLAS_BASE=#{openblas.opt_prefix}",
           "FFTW_BASE=#{fftw.opt_prefix}"

    bin.install "bart"
  end

  test do
    assert_match "v1.0.00", shell_output("#{bin}/bart version")
  end
end
