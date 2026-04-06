class Ismrmrd < Formula
  desc "ISMRM Raw Data format — library and tools for MRI raw data"
  homepage "https://ismrmrd.github.io"
  url "https://github.com/ismrmrd/ismrmrd/archive/refs/tags/v1.15.0.tar.gz"
  sha256 "57739de6d93203adc86f5e510729b7e2a45917bcab480dd1c1a6b6d16508a42c"
  license "MIT"

  depends_on "cmake" => :build
  depends_on "boost"
  depends_on "fftw"
  depends_on "hdf5"
  depends_on "pugixml"

  def install
    # Disable -Werror to avoid build failures with newer compilers
    inreplace "CMakeLists.txt", "-Wall -Werror", "-Wall"

    args = %w[
      -DBUILD_TESTS=OFF
      -DBUILD_EXAMPLES=OFF
      -DUSE_HDF5_DATASET_SUPPORT=ON
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build", "--parallel", ENV.make_jobs
    system "cmake", "--install", "build"
  end

  test do
    assert_match "ismrmrd", shell_output("#{bin}/ismrmrd_info 2>&1")
  end
end
