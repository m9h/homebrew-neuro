class Brainflow < Formula
  desc "Biosensor Library (EEG, EMG, ECG)"
  homepage "https://brainflow.org"
  url "https://github.com/brainflow-dev/brainflow/archive/refs/tags/5.19.0.tar.gz"
  sha256 "047e81d69ae2fdf1cb78a291d0f07e89be53d278c27cc2f44889239da27d4a4c"
  license "MIT"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "libusb"
  depends_on "openblas"

  def install
    args = %w[
      -GNinja
      -DBUILD_OYMOTION_SDK=OFF
      -DBUILD_GFORCE_SDK=OFF
      -DBUILD_GFORCE_PRO_SDK=OFF
      -DBUILD_SHARED_LIBS=ON
      -DKISSFFT_STATIC=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    # Ensure C++ headers are available in a standard location
    (include/"brainflow").install Dir["src/board_controller/inc/*.h"]
    (include/"brainflow").install Dir["src/data_handler/inc/*.h"]
    (include/"brainflow").install Dir["src/ml_module/inc/*.h"]
    (include/"brainflow").install Dir["src/utils/inc/*.h"]
    (include/"brainflow").install Dir["cpp_package/src/inc/*.h"]
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include "brainflow/board_shim.h"
      int main() {
        BoardShim::set_log_level(6);
        return 0;
      }
    CPP
    system ENV.cxx, "test.cpp", "-I#{include}", "-o", "test"
    system "./test"
  end
end
