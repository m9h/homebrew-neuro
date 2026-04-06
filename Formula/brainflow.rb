class Brainflow < Formula
  desc "Library for obtaining EEG, EMG, ECG, and other biosignal data"
  homepage "https://brainflow.org"
  url "https://github.com/brainflow-dev/brainflow/archive/refs/tags/5.21.0.tar.gz"
  sha256 "63fed79f128b8db05c81bc1be37812c181d311165ee29f7c2e6aaca792dc2472"
  license "MIT"

  depends_on "cmake" => :build

  def install
    args = %w[
      -DCMAKE_BUILD_TYPE=Release
      -DBUILD_BLUETOOTH=OFF
      -DBUILD_BLE=OFF
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build", "--parallel", ENV.make_jobs
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <board_controller.h>
      int main() { return 0; }
    C
    system ENV.cc, "test.c", "-I#{include}", "-o", "test"
  end
end
