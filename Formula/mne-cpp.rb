class MneCpp < Formula
  desc "MNE-CPP — cross-platform C++ library for MEG and EEG data processing"
  homepage "https://mne-cpp.github.io"
  url "https://github.com/mne-tools/mne-cpp/archive/refs/tags/v2.1.0.tar.gz"
  sha256 "f8afb082abe22d963ae6ebc6ff5862276b156cb27f2a15a0b32e9de9c51cbf54"
  license "BSD-3-Clause"

  depends_on "cmake" => :build
  depends_on "eigen@3"
  depends_on "qt"

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build", "--parallel", ENV.make_jobs
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <iostream>
      int main() { std::cout << "mne-cpp ok" << std::endl; return 0; }
    CPP
    system ENV.cxx, "test.cpp", "-o", "test"
    system "./test"
  end
end
