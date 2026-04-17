class Ants < Formula
  desc "Advanced Normalization Tools — medical image registration and segmentation"
  homepage "https://github.com/ANTsX/ANTs"
  url "https://github.com/ANTsX/ANTs/archive/refs/tags/v2.6.5.tar.gz"
  sha256 "c089cb8deac83cad51605299f38c418fdf2023c2e4d924cf4ccbe1a6f376740f"
  license "Apache-2.0"

  depends_on "cmake" => :build
  depends_on "mhough/neuro/itk-neuro"

  def install
    # ANTs hardcodes CMAKE_INSTALL_PREFIX=/opt/ANTs as CACHE variable —
    # must remove it so std_cmake_args can set it properly
    inreplace "CMakeLists.txt",
              'SET(CMAKE_INSTALL_PREFIX /opt/ANTs CACHE PATH "Default ANTs install path")',
              "# install prefix set by brew"

    args = %W[
      -DANTS_SUPERBUILD=OFF
      -DUSE_SYSTEM_ITK=ON
      -DBUILD_TESTING=OFF
      -DBUILD_SHARED_LIBS=ON
      -DUSE_VTK=OFF
      -DCMAKE_INSTALL_PREFIX:PATH=#{prefix}
      -DCMAKE_INSTALL_RPATH=#{lib}
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build", "--parallel", ENV.make_jobs
    system "cmake", "--install", "build"
  end

  test do
    assert_match "ANTs", shell_output("#{bin}/antsRegistration --version 2>&1")
  end
end
