class Elastix < Formula
  desc "Medical image registration toolbox"
  homepage "https://elastix.dev"
  url "https://github.com/SuperElastix/elastix/archive/refs/tags/5.3.1.tar.gz"
  sha256 "f4f69b3e94f8b2f7cc53899e63192c501e4c78e630388e2034fabf848cbc89f7"
  license "Apache-2.0"

  depends_on "cmake" => :build
  depends_on "double-conversion"
  depends_on "mhough/neuro/itk-neuro"

  def install
    dc = Formula["double-conversion"]
    ENV.append "CXXFLAGS", "-I#{dc.opt_include}/double-conversion"

    args = %w[
      -DBUILD_TESTING=OFF
      -DELASTIX_USE_OPENCL=OFF
      -DUSE_ALL_COMPONENTS=OFF
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build", "--parallel", ENV.make_jobs
    system "cmake", "--install", "build"
  end

  test do
    assert_match "elastix", shell_output("#{bin}/elastix --version 2>&1")
  end
end
