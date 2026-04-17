class ItkNeuro < Formula
  desc "ITK with remote modules for neuroimaging (ANTs, FreeSurfer IO, etc.)"
  homepage "https://itk.org"
  url "https://github.com/InsightSoftwareConsortium/ITK/releases/download/v5.4.5/InsightToolkit-5.4.5.tar.gz"
  sha256 "ecab9119664e2571b90740ba9ab3ca11cb46942dbd7bb87c0de5bb15309a36c9"
  license "Apache-2.0"

  depends_on "cmake" => :build
  depends_on "dcmtk"
  depends_on "double-conversion"
  depends_on "fftw"
  depends_on "gdcm"
  depends_on "hdf5"
  depends_on "jpeg-turbo"
  depends_on "libpng"
  depends_on "libtiff"
  # VTK/ITKVtkGlue disabled to avoid Python version conflicts with VTK bottle
  # depends_on "vtk"

  uses_from_macos "expat"

  on_macos do
    depends_on "freetype"
    depends_on "glew"
  end

  # Conflicts with brew's itk — same libraries, different modules
  conflicts_with "itk", because: "itk-neuro is ITK with extra neuroimaging modules"

  def install
    # Avoid CMake trying to find GoogleTest even though tests are disabled
    rm_r(buildpath/"Modules/ThirdParty/GoogleTest")

    args = %W[
      -DBUILD_SHARED_LIBS=ON
      -DCMAKE_INSTALL_RPATH:STRING=#{lib}
      -DCMAKE_INSTALL_NAME_DIR:STRING=#{lib}
      -DITKV3_COMPATIBILITY:BOOL=OFF
      -DITK_LEGACY_REMOVE=OFF
      -DITK_USE_64BITS_IDS=ON
      -DITK_USE_FFTWF=ON
      -DITK_USE_FFTWD=ON
      -DITK_USE_SYSTEM_FFTW=ON
      -DITK_USE_SYSTEM_HDF5=ON
      -DITK_USE_SYSTEM_JPEG=ON
      -DITK_USE_SYSTEM_PNG=ON
      -DITK_USE_SYSTEM_TIFF=ON
      -DITK_USE_SYSTEM_GDCM=ON
      -DITK_USE_SYSTEM_ZLIB=ON
      -DITK_USE_SYSTEM_EXPAT=ON
      -DITK_USE_SYSTEM_DOUBLECONVERSION=ON
      -DITK_USE_SYSTEM_LIBRARIES=ON
      -DModule_ITKReview=ON
      -DModule_ITKVtkGlue=OFF
      -DModule_SCIFIO=OFF
      -DModule_ITKDCMTK=ON
      -DModule_ITKIODCMTK=ON
      -DModule_IOTransformMINC=ON
      -DModule_GenericLabelInterpolator=ON
      -DModule_AdaptiveDenoising=ON
      -DModule_MGHIO=ON
    ]

    # Avoid references to the Homebrew shims directory
    inreplace "Modules/Core/Common/src/CMakeLists.txt" do |s|
      s.gsub!(/MAKE_MAP_ENTRY\(\s*\\"CMAKE_C_COMPILER\\",
              \s*\\"\${CMAKE_C_COMPILER}\\".*\);/x,
              "MAKE_MAP_ENTRY(\\\"CMAKE_C_COMPILER\\\", " \
              "\\\"#{ENV.cc}\\\", \\\"The C compiler.\\\");")

      s.gsub!(/MAKE_MAP_ENTRY\(\s*\\"CMAKE_CXX_COMPILER\\",
              \s*\\"\${CMAKE_CXX_COMPILER}\\".*\);/x,
              "MAKE_MAP_ENTRY(\\\"CMAKE_CXX_COMPILER\\\", " \
              "\\\"#{ENV.cxx}\\\", \\\"The CXX compiler.\\\");")
    end

    # Fix versioned macOS SDK paths for bottle portability
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    if OS.mac?
      sdk_path = MacOS.sdk_path.to_s
      generic_sdk = "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
      if sdk_path != generic_sdk
        Dir.glob(lib/"cmake/ITK-#{version.major_minor}/*.cmake").each do |f|
          inreplace f, sdk_path, generic_sdk, audit_result: false
        end
      end
    end

    # Remove the bundled JRE if present (from SCIFIO)
    rm_r(lib/"jre") if (lib/"jre").exist?
  end

  test do
    (testpath/"test.cxx").write <<~CPP
      #include "itkImage.h"
      int main(int argc, char* argv[])
      {
        typedef itk::Image<unsigned short, 3> ImageType;
        ImageType::Pointer image = ImageType::New();
        image->Update();
        return EXIT_SUCCESS;
      }
    CPP

    v = version.major_minor
    system ENV.cxx, "-std=c++17", "-isystem", "#{include}/ITK-#{v}", "-o", "test.cxx.o", "-c", "test.cxx"
    system ENV.cxx, "-std=c++17", "test.cxx.o", "-o", "test",
                    lib/shared_library("libITKCommon-#{v}", 1),
                    lib/shared_library("libITKVNLInstantiation-#{v}", 1),
                    lib/shared_library("libitkvnl_algo-#{v}", 1),
                    lib/shared_library("libitkvnl-#{v}", 1)
    system "./test"
  end
end
