class SlicerExecutionModel < Formula
  desc "CMake macros and tools for building 3D Slicer CLI modules"
  homepage "https://github.com/Slicer/SlicerExecutionModel"
  url "https://github.com/Slicer/SlicerExecutionModel/archive/3bd8e038024b5a0684bf8284d4af0ac69cc0eb3c.tar.gz"
  version "2.0.0-20260301"
  sha256 "6b0fed5b2ecea2f4b3c03939c52cf0f18adf2e2d1b84457de053bb3408977f40"
  license "3D-Slicer-1.0"

  depends_on "cmake" => :build
  depends_on "itk-neuro"

  uses_from_macos "expat"

  def install
    # itk-neuro version might change, so we find it dynamically
    itk_dir = Formula["itk-neuro"].opt_lib/"cmake/ITK-#{Formula["itk-neuro"].version.major_minor}"

    args = %W[
      -DBUILD_SHARED_LIBS=ON
      -DBUILD_TESTING=OFF
      -DCMAKE_CXX_STANDARD=17
      -DCMAKE_CXX_STANDARD_REQUIRED=ON
      -DITK_DIR=#{itk_dir}
      -DSlicerExecutionModel_USE_JSONCPP=OFF
      -DSlicerExecutionModel_USE_UTF8=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.10)
      project(TestSEM)
      find_package(SlicerExecutionModel REQUIRED)
    EOS
    # This test might fail if SlicerExecutionModelConfig.cmake is not properly installed
    # as noted in the neurofedora-species spec (which applied many patches).
    # We'll see if the default build installs enough for a find_package.
    system "cmake", "."
  end
end
