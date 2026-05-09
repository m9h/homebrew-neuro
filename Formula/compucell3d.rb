class Compucell3d < Formula
  desc "Multi-scale Virtual Tissue Modeling Environment"
  homepage "https://compucell3d.org/"
  url "https://github.com/CompuCell3D/CompuCell3D/archive/refs/tags/4.5.0.tar.gz"
  sha256 "2d2367e0fc2a996ddcc20a3f04344281c20311c79e664e9eedee1226e5e55203"
  license "MIT"

  depends_on "cmake" => :build
  depends_on "swig" => :build
  depends_on "eigen"
  depends_on "python@3.12"
  depends_on "qt@5"
  depends_on "tbb"
  depends_on "vtk"

  def install
    python3 = Formula["python@3.12"].opt_bin/"python3.12"

    args = %W[
      -DCMAKE_BUILD_TYPE=Release
      -DPYTHON_EXECUTABLE=#{python3}
      -DCOMPUCELL3D_INSTALL_PATH=#{libexec}
      -DBUILD_SHARED_LIBS=ON
      -DNO_OPENGL=OFF
    ]

    system "cmake", "-S", "CompuCell3D", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    # Create bin wrapper
    (bin/"compucell3d").write <<~EOS
      #!/bin/bash
      export PYTHONPATH="#{libexec}/lib/python"
      exec "#{libexec}/compucell3d.sh" "$@"
    EOS
  end

  test do
    assert_path_exists bin/"compucell3d"
  end
end
