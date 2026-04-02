class CharmGems < Formula
  desc "C++ segmentation library with Python bindings for SimNIBS CHARM"
  homepage "https://github.com/simnibs/charm-gems"
  url "https://github.com/simnibs/charm-gems/archive/refs/tags/v1.3.3.tar.gz"
  sha256 "b894dc2f050dad338c99eab4b8db34964115c3dbb2397b515d264a0b8508928f"
  license "GPL-3.0-or-later"

  depends_on "cmake" => :build
  depends_on "python@3.13"

  resource "itk" do
    url "https://github.com/InsightSoftwareConsortium/ITK/archive/refs/tags/v4.13.2.tar.gz"
    sha256 "98c2fd826e1987d797521d83031fcaa328135daf6524f7823363d66ab288c545"
  end

  resource "pybind11" do
    url "https://github.com/pybind/pybind11/archive/refs/tags/v2.13.6.tar.gz"
    sha256 "e08cb87f4773da97fa7b5f035de8763abc656d87d5773e62f6da0587d1f0ec20"
  end

  # Patch ITK 4.13.2 for CMake 4.x and modern macOS SDK
  def patch_itk(itk_dir)
    # Use sed for all patching to avoid homebrew's File.write restrictions
    system "find", itk_dir, "-name", "CMakeLists.txt", "-o", "-name", "*.cmake",
           "-exec", "sed", "-i", "",
           "-E", "s/[Cc][Mm][Aa][Kk][Ee]_[Mm][Ii][Nn][Ii][Mm][Uu][Mm]_[Rr][Ee][Qq][Uu][Ii][Rr][Ee][Dd]\\(VERSION [0-9]+\\.[0-9]+(\\.[0-9]+)?( FATAL_ERROR)?\\)/cmake_minimum_required(VERSION 3.5...4.0)/g",
           "{}", ";"

    # Remove Documentation.cmake include (fatal in CMake 4.x)
    system "sed", "-i", "",
           "s/.*include.*Documentation\\.cmake.*/option(BUILD_DOCUMENTATION \"Build documentation\" OFF)/",
           "#{itk_dir}/Utilities/Doxygen/CMakeLists.txt"

    # Fix fp.h include (removed from modern macOS SDK)
    # Replace the #if MWERKS...fp.h...#else...math.h...#endif block with just math.h
    system "sed", "-i", "",
           "/#.*defined(__MWERKS__)/,/^#  endif$/c\\
#  include <math.h>",
           "#{itk_dir}/Modules/ThirdParty/PNG/src/itkpng/pngpriv.h"
  end

  def install
    (buildpath/"ITK").install resource("itk")
    (buildpath/"pybind11").install resource("pybind11")

    ENV["CMAKE_POLICY_VERSION_MINIMUM"] = "3.5"

    patch_itk(buildpath/"ITK")

    # Build ITK as static library
    mkdir "ITK-build" do
      system "cmake", "-G", "Unix Makefiles",
             "-DCMAKE_BUILD_TYPE=Release",
             "-DBUILD_SHARED_LIBS=OFF",
             "-DBUILD_TESTING=OFF",
             "-DBUILD_EXAMPLES=OFF",
             "-DBUILD_DOCUMENTATION=OFF",
             buildpath/"ITK"
      system "make", "-j#{ENV.make_jobs}"
    end

    # Build charm-gems Python package
    python3 = Formula["python@3.13"].opt_bin/"python3.13"
    ENV["ITK_DIR"] = buildpath/"ITK-build"
    system python3, "-m", "pip", "install", "--prefix=#{prefix}", ".", "-v"
  end

  test do
    python3 = Formula["python@3.13"].opt_bin/"python3.13"
    system python3, "-c", "import charm_gems; print(charm_gems.KvlImage)"
  end
end
