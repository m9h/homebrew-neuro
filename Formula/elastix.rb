class Elastix < Formula
  desc "Toolbox for rigid and nonrigid registration of images"
  homepage "https://github.com/SuperElastix/elastix"
  url "https://github.com/SuperElastix/elastix/archive/ef34ca9.tar.gz"
  version "5.3.1-20260423"
  sha256 "ff17ecc4c4c4b2f4359c50c8b471ee8458b42c8cbbe14e9e90b16899e1d9c5d2"
  license "Apache-2.0"

  depends_on "cmake" => :build
  depends_on "eigen"
  depends_on "itk-neuro"
  depends_on "libminc"

  def install
    itk_dir = Formula["itk-neuro"].opt_lib/"cmake/ITK-#{Formula["itk-neuro"].version.major_minor}"

    args = %W[
      -DITK_DIR=#{itk_dir}
      -DELASTIX_USE_EIGEN=ON
      -DBUILD_TESTING=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system "#{bin}/elastix", "--version"
  end
end
