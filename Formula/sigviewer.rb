class Sigviewer < Formula
  desc "Viewing application for biosignals (EDF, GDF, BDF, XDF)"
  homepage "https://github.com/cbrnr/sigviewer"
  url "https://github.com/cbrnr/sigviewer/archive/refs/tags/v0.6.5.tar.gz"
  sha256 "a08e599c142b0b7750380301cea3cd6eb324dab8342bad2e2441da0aa9c627ed"
  license "GPL-3.0-or-later"

  depends_on "cmake" => :build
  depends_on "autoconf" => :build
  depends_on "qt"
  depends_on "suite-sparse"

  def install
    # Build external deps (libxdf + libbiosig) from source
    system "cmake", "-P", "external/build_deps.cmake"

    # Build sigviewer
    system "cmake", "-S", ".", "-B", "build", "-DCMAKE_BUILD_TYPE=Release", *std_cmake_args
    system "cmake", "--build", "build", "--parallel", ENV.make_jobs

    prefix.install "build/SigViewer.app"
    bin.install_symlink prefix/"SigViewer.app/Contents/MacOS/SigViewer" => "sigviewer"
  end

  test do
    assert_match "SigViewer 0.6.5", shell_output("#{bin}/sigviewer --version 2>&1")
  end
end
