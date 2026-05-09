class Jemris < Formula
  desc "Juelich Extensible MRI Simulator"
  homepage "https://github.com/JEMRIS/jemris"
  url "https://github.com/JEMRIS/jemris/archive/refs/tags/v2.9.2.tar.gz"
  sha256 "a5db62c1479646ce32a819c8b46bead525d888004b1ba6ae56089b3a787b41f4"
  license "GPL-2.0-or-later"

  depends_on "cmake" => :build
  depends_on "boost"
  depends_on "cln"
  depends_on "ginac"
  depends_on "hdf5"
  depends_on "m9h/neuro/ismrmrd"
  depends_on "open-mpi"
  depends_on "sundials"
  depends_on "xerces-c"

  def install
    # Remove hardcoded mpicxx compiler
    inreplace "CMakeLists.txt", /set\(CMAKE_CXX_COMPILER.*/, ""

    # Remove the docker pull block entirely
    inreplace "CMakeLists.txt" do |s|
      s.gsub!(/^# Docker image.*endif\(\)$/m, "")
    end

    # Fix SUNDIALS 7.x types (realtype -> sunrealtype)
    # Using Dir.glob for robustness
    Dir.glob("src/**/*.{cpp,h}").each do |f|
      inreplace f, /\brealtype\b/, "sunrealtype"
    end

    # Fix SUNDIALS 7.x API
    Dir.glob("src/**/*.cpp").each do |f|
      inreplace f, /SUNContext_Create\( &comm,/, "SUNContext_Create( comm,"
      inreplace f, /CVodeSetErrFile.*/, ""
    end

    # Fix HDF5/size_t conflict in NDData.h
    inreplace "src/NDData.h", /NDData \(const std::vector<hsize_t>& dims\).*?}/m, ""

    # Add missing includes for newer GCC
    inreplace "src/NDData.h", /^/, "#include <cstdint>\n#include <stdexcept>\n#include <algorithm>\n"

    args = %w[
      -DSKIP_CONDA=ON
      -DJEMRIS_ENABLE_MPI=ON
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system bin/"jemris", "--version"
  end
end
