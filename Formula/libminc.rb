class Libminc < Formula
  desc "Core library for the MINC medical imaging format"
  homepage "https://github.com/BIC-MNI/libminc"
  url "https://github.com/BIC-MNI/libminc/archive/refs/tags/release-2.4.03.tar.gz"
  sha256 "138eded8a4958e2735178ce41e687af25d4c7a4127b67b853a40165d5d1962f5"
  license "BSD-3-Clause"

  depends_on "cmake" => :build
  depends_on "hdf5"
  depends_on "netcdf"

  def install
    system "cmake", "-S", ".", "-B", "build", "-DLIBMINC_BUILD_V2=ON", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <minc2.h>
      int main() {
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lminc2", "-o", "test"
    system "./test"
  end
end
