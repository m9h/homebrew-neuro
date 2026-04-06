class Libxdf < Formula
  desc "C++ library for reading XDF (Extensible Data Format) files"
  homepage "https://github.com/xdf-modules/libxdf"
  url "https://github.com/xdf-modules/libxdf/archive/refs/tags/v0.99.10.tar.gz"
  sha256 "b941b7aa5b75fda2da126cee67028d3754d86830fcc6ed0e00ceddcfa501b594"
  license "BSD-2-Clause"

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-DXDF_NO_SYSTEM_PUGIXML=ON", *std_cmake_args
    system "cmake", "--build", "build", "--parallel", ENV.make_jobs
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <xdf.h>
      int main() { Xdf xdf; return 0; }
    CPP
    system ENV.cxx, "-std=c++20", "test.cpp", "-I#{include}", "-L#{lib}", "-lxdf", "-o", "test"
    system "./test"
  end
end
