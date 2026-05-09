class Greedy < Formula
  desc "Very fast greedy diffeomorphic image registration tool"
  homepage "https://github.com/pyushkevich/greedy"
  url "https://github.com/pyushkevich/greedy/archive/3a567534db45cf3178b78cc9c9194cf0bc501a5f.tar.gz"
  version "1.0.1-20240905"
  sha256 "e998341c6ccc1f09ba66fae71822d2a40b3cfcf4abe8e9103b7aa20659fd6093"
  license "GPL-3.0-or-later"

  depends_on "cmake" => :build
  depends_on "itk-neuro"
  depends_on "vtk"

  def install
    # itk-neuro version might change, so we find it dynamically
    itk_dir = Formula["itk-neuro"].opt_lib/"cmake/ITK-#{Formula["itk-neuro"].version.major_minor}"

    args = %W[
      -DITK_DIR=#{itk_dir}
      -DBUILD_GUI=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system "#{bin}/greedy", "-h"
  end
end
