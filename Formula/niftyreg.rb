class Niftyreg < Formula
  desc "Medical image registration tools (NiftyReg)"
  homepage "https://github.com/KCL-BMEIS/niftyreg"
  url "https://github.com/KCL-BMEIS/niftyreg/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "dffd2a47b82d83ca8e466c25e19f56126b2aeec0e69eb37d618ee83b4ac39d4a"
  license "BSD-3-Clause"

  depends_on "cmake" => :build

  def install
    # Set version explicitly since git tags aren't available from tarball
    inreplace "CMakeLists.txt",
              "set(NR_VERSION ${${PROJECT_NAME}_VERSION})",
              "set(NR_VERSION \"#{version}\")\nset(${PROJECT_NAME}_VERSION \"#{version}\")"

    args = %w[
      -DUSE_CUDA=OFF
      -DUSE_OPENCL=OFF
      -DBUILD_TESTING=OFF
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build", "--parallel", ENV.make_jobs
    system "cmake", "--install", "build"
  end

  test do
    assert_match "Block Matching", shell_output("#{bin}/reg_aladin --help 2>&1", 1)
  end
end
