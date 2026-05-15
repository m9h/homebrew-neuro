class Mmg < Formula
  desc "Tetrahedral, triangular and edge mesh modification library"
  homepage "https://www.mmgtools.org/"
  url "https://github.com/MmgTools/mmg/archive/refs/tags/v5.8.0.tar.gz"
  sha256 "686eaab84de79c072f3aedf26cd11ced44c84b435d51ce34e016ad203172922f"
  license "LGPL-3.0-or-later"
  head "https://github.com/MmgTools/mmg.git", branch: "develop"

  depends_on "cmake" => :build

  def install
    # mmg's CMakeLists sets CMAKE_MACOSX_RPATH=1 but never populates
    # CMAKE_INSTALL_RPATH, so the executables ship with no LC_RPATH and
    # can't locate libmmg3d.5.dylib at runtime. Inject the standard
    # bin->lib relative rpath here.
    system "cmake", "-S", ".", "-B", "build",
                    "-DBUILD_SHARED_LIBS=ON",
                    "-DBUILD_TESTING=OFF",
                    "-DCMAKE_INSTALL_RPATH=@loader_path/../lib",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    # mmg3d_O3 is the standard tetrahedral mesh modifier binary. It always
    # exits non-zero when invoked without an input mesh, so check that it
    # at least launches (which exercises the libmmg* rpath) and emits its
    # version banner.
    assert_path_exists bin/"mmg3d_O3"
    output = shell_output("#{bin}/mmg3d_O3 -h 2>&1", 2)
    assert_match version.to_s, output
  end
end
