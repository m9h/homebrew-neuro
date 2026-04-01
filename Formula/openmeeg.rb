class Openmeeg < Formula
  desc "BEM solver for forward problems in EEG and MEG"
  homepage "https://openmeeg.github.io"
  url "https://github.com/openmeeg/openmeeg/archive/refs/tags/2.5.16.tar.gz"
  sha256 "29485a732e3555425889cfd28474fccd2b3e76b51bb694fc83d86ca052e70884"
  license "CECILL-B"

  depends_on "cmake" => :build
  depends_on "hdf5"
  depends_on "libmatio"
  depends_on "openblas"

  def install
    openblas = Formula["openblas"]

    args = %W[
      -DCMAKE_BUILD_TYPE=Release
      -DUSE_VTK=OFF
      -DUSE_GIFTI=OFF
      -DUSE_CGAL=OFF
      -DENABLE_PYTHON=OFF
      -DBUILD_TESTING=OFF
      -DBLA_IMPLEMENTATION=OpenBLAS
      -DCMAKE_CXX_FLAGS=-I#{openblas.opt_include}
      -DCMAKE_C_FLAGS=-I#{openblas.opt_include}
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build", "--parallel", ENV.make_jobs
    system "cmake", "--install", "build"
  end

  test do
    assert_match "2.5.16", shell_output("#{bin}/om_assemble 2>&1")
  end
end
