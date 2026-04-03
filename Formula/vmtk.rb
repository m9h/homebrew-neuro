class Vmtk < Formula
  desc "Vascular Modeling Toolkit — vessel segmentation, centerlines, and CFD preprocessing"
  homepage "http://www.vmtk.org"
  url "https://github.com/m9h/vmtk/archive/10d8fbd2a175dead9b2112f70acc26a48c738262.tar.gz"
  version "1.5.1"
  sha256 "733cb8a3aeb5b9d7aba63d3410057d9ca7eac124bd5b0c45852eb1608ce17ca1"
  license "BSD-3-Clause"

  depends_on "cmake" => :build
  depends_on "itk"
  depends_on "vtk"

  def install
    args = %W[
      -DCMAKE_BUILD_TYPE=Release
      -DVMTK_USE_SUPERBUILD=OFF
      -DUSE_SYSTEM_VTK=ON
      -DUSE_SYSTEM_ITK=ON
      -DVMTK_USE_VTK9=ON
      -DVMTK_USE_ITK5=ON
      -DVTK_VMTK_WRAP_PYTHON=OFF
      -DVMTK_BUILD_TESTING=OFF
      -DBUILD_SHARED_LIBS=ON
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build", "--parallel", ENV.make_jobs
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cxx").write <<~CPP
      #include <vtkvmtkCommon.h>
      int main() { return 0; }
    CPP
    system ENV.cxx, "test.cxx", "-I#{include}/vmtk", "-o", "test"
  end
end
