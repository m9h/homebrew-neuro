class CharmGems < Formula
  desc "C++ segmentation library with Python bindings for SimNIBS CHARM"
  homepage "https://github.com/simnibs/charm-gems"
  url "https://github.com/simnibs/charm-gems/archive/refs/tags/v1.3.3.tar.gz"
  sha256 "b894dc2f050dad338c99eab4b8db34964115c3dbb2397b515d264a0b8508928f"
  license "GPL-3.0-or-later"

  depends_on "cmake" => :build
  depends_on "python@3.13"

  resource "itk" do
    url "https://github.com/InsightSoftwareConsortium/ITK.git",
        tag:      "v4.13.2",
        revision: "1c3f5fe847e15fdae24cf4609fd7945e88ec0a18"
  end

  resource "pybind11" do
    url "https://github.com/pybind/pybind11.git",
        tag:      "v2.6.2",
        revision: "be97c5a98b4b252c524566f508b5c79410d118c6"
  end

  def install
    # Checkout submodules into place
    (buildpath/"ITK").install resource("itk")
    (buildpath/"pybind11").install resource("pybind11")

    # --- ITK 4.13.2 patches for CMake 4.x + modern macOS SDK ---

    # Patch cmake_minimum_required throughout ITK for CMake 4.x compat
    Dir.glob(buildpath/"ITK/**/{CMakeLists.txt,*.cmake}").each do |f|
      content = File.read(f)
      next unless content.match?(/cmake_minimum_required\s*\(\s*VERSION\s+[0-3]\.\d+/i)

      content.gsub!(/cmake_minimum_required\s*\(\s*VERSION\s+[0-3]\.\d+(\.\d+)?(\s+FATAL_ERROR)?\s*\)/i,
                     "cmake_minimum_required(VERSION 3.5...4.0)")
      File.write(f, content)
    end

    # Remove Documentation.cmake include (removed in CMake 4.x, CMP0106)
    inreplace "ITK/Utilities/Doxygen/CMakeLists.txt",
              /.*include.*Documentation\.cmake.*/,
              'option(BUILD_DOCUMENTATION "Build documentation" OFF)'

    # Fix fp.h include (removed from modern macOS SDK)
    inreplace "ITK/Modules/ThirdParty/PNG/src/itkpng/pngpriv.h",
              /#\s*if\s*\(defined\(__MWERKS__\).*?#\s*include\s*<math\.h>\n#\s*endif/m,
              "#  include <math.h>"

    # --- Build ITK as static library ---
    mkdir "ITK-build" do
      system "cmake", "-G", "Unix Makefiles",
             "-DCMAKE_BUILD_TYPE=Release",
             "-DBUILD_SHARED_LIBS=OFF",
             "-DBUILD_TESTING=OFF",
             "-DBUILD_EXAMPLES=OFF",
             "-DBUILD_DOCUMENTATION=OFF",
             buildpath/"ITK"
      ENV["CMAKE_POLICY_VERSION_MINIMUM"] = "3.5"
      system "make", "-j#{ENV.make_jobs}"
    end

    # --- Build charm-gems Python wheel ---
    python3 = Formula["python@3.13"].opt_bin/"python3.13"
    ENV["ITK_DIR"] = buildpath/"ITK-build"
    ENV["CMAKE_POLICY_VERSION_MINIMUM"] = "3.5"
    system python3, "-m", "pip", "install", "--prefix=#{prefix}", ".", "-v"
  end

  test do
    python3 = Formula["python@3.13"].opt_bin/"python3.13"
    system python3, "-c", "import charm_gems; print(charm_gems.KvlImage)"
  end
end
