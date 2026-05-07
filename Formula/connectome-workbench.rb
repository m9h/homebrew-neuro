class ConnectomeWorkbench < Formula
  desc "Visualization and analysis tool for brain imaging data (HCP)"
  homepage "https://www.humanconnectome.org/software/connectome-workbench"
  url "https://github.com/Washington-University/workbench/archive/refs/tags/v2.1.0.tar.gz"
  sha256 "a6bd9cf06cb7a734883866b862219b1a1128557e0d23aa7767d5028e28a45901"
  license "GPL-2.0-or-later"

  depends_on "cmake" => :build
  depends_on "freetype"
  depends_on "openssl@3"
  depends_on "qt"

  def install
    # Fix cmake_minimum_required for CMake 4.x compatibility
    %w[src/kloewe/cpuinfo/CMakeLists.txt src/kloewe/dot/CMakeLists.txt].each do |f|
      inreplace f, "cmake_minimum_required(VERSION 3.0)",
                   "cmake_minimum_required(VERSION 3.5...4.0)"
    end

    # Fix FreeType 2.13+ API change: outline.tags is now unsigned char*
    inreplace "src/FtglFont/FTContour.h",
              "FTContour(FT_Vector* contour, char* pointTags, unsigned int numberOfPoints);",
              "FTContour(FT_Vector* contour, const unsigned char* pointTags, unsigned int numberOfPoints);"
    inreplace "src/FtglFont/FTContour.cpp",
              "FTContour::FTContour(FT_Vector* contour, char* tags, unsigned int n)",
              "FTContour::FTContour(FT_Vector* contour, const unsigned char* tags, unsigned int n)"
    inreplace "src/FtglFont/FTVectoriser.cpp",
              "char* tagList = &outline.tags[startIndex];",
              "const unsigned char* tagList = &outline.tags[startIndex];"

    args = %w[
      -DCMAKE_BUILD_TYPE=Release
      -DWORKBENCH_USE_QT6=TRUE
      -DWORKBENCH_USE_QT5=FALSE
      -DWORKBENCH_APPLE_WB_COMMAND_BUNDLE_FLAG=FALSE
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    ]

    system "cmake", "-S", "src", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build", "--parallel", ENV.make_jobs
    bin.install "build/CommandLine/wb_command"
    prefix.install "build/Desktop/wb_view.app"
    bin.install_symlink prefix/"wb_view.app/Contents/MacOS/wb_view"
  end

  test do
    assert_match "Connectome Workbench", shell_output("#{bin}/wb_command -version")
    assert_match "2.1.0", shell_output("#{bin}/wb_command -version")
  end
end
