class Geant4 < Formula
  desc "Toolkit for simulating the passage of particles through matter"
  homepage "https://geant4.web.cern.ch/"
  url "https://github.com/Geant4/geant4/archive/refs/tags/v11.3.2.tar.gz"
  sha256 "7c9e4bd65cc3f4fd525cd35c50c5376f131805b2dce622fcdf19f63ff78ad373"
  license "Apache-2.0"

  depends_on "cmake" => :build
  depends_on "clhep"
  depends_on "expat"
  depends_on "qt"
  depends_on "xerces-c"

  def install
    args = %w[
      -DGEANT4_INSTALL_DATA=ON
      -DGEANT4_USE_SYSTEM_CLHEP=ON
      -DGEANT4_USE_SYSTEM_EXPAT=ON
      -DGEANT4_USE_SYSTEM_ZLIB=ON
      -DGEANT4_USE_GDML=ON
      -DGEANT4_BUILD_MULTITHREADED=ON
      -DGEANT4_USE_QT=ON
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include "G4RunManager.hh"
      int main() {
        G4RunManager* runManager = new G4RunManager;
        delete runManager;
        return 0;
      }
    CPP
    system ENV.cxx, "test.cpp", "-I#{include}/Geant4", "-o", "test"
    system "./test"
  end
end
