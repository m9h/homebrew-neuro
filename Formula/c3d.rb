class C3d < Formula
  desc "Convert3D — medical image processing tool"
  homepage "http://www.itksnap.org/c3d"
  url "https://github.com/pyushkevich/c3d/archive/refs/tags/v1.4.6.tar.gz"
  sha256 "777d3a44d1100a84281249830ecde658ed194c0be32b010e075d05146066b37e"
  license "GPL-3.0-or-later"

  depends_on "cmake" => :build
  depends_on "itk"

  def install
    args = %w[
      -DBUILD_GUI=OFF
      -DBUILD_TESTING=OFF
      -DCONVERT3D_USE_ITK_REMOTE_MODULES=OFF
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build", "--parallel", ENV.make_jobs
    system "cmake", "--install", "build"
  end

  test do
    assert_match "Convert3D", shell_output("#{bin}/c3d -version 2>&1")
  end
end
