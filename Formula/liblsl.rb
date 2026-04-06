class Liblsl < Formula
  desc "C/C++ library for multi-modal time-synced data streaming (Lab Streaming Layer)"
  homepage "https://labstreaminglayer.org"
  url "https://github.com/sccn/liblsl/archive/refs/tags/v1.17.5.tar.gz"
  sha256 "6f1f5a3fc4c4a162c86ced19c75d13a81d8ebe1f819c50caf257b1ee0b401d1a"
  license "MIT"

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-DLSL_BUILD_STATIC=OFF", *std_cmake_args
    system "cmake", "--build", "build", "--parallel", ENV.make_jobs
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <lsl_c.h>
      int main() { return lsl_library_info() != 0 ? 0 : 1; }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-llsl", "-o", "test"
    system "./test"
  end
end
