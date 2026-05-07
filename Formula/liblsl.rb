class Liblsl < Formula
  desc "C/C++ library for multi-modal time-synced data streaming (Lab Streaming Layer)"
  homepage "https://labstreaminglayer.org"
  url "https://github.com/sccn/liblsl/archive/refs/tags/v1.17.5.tar.gz"
  sha256 "6f1f5a3fc4c4a162c86ced19c75d13a81d8ebe1f819c50caf257b1ee0b401d1a"
  license "MIT"

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DLSL_BUILD_STATIC=OFF",
                    "-DLSL_FRAMEWORK=OFF",
                    *std_cmake_args
    system "cmake", "--build", "build", "--parallel", ENV.make_jobs
    system "cmake", "--install", "build"

    # Upstream hard-codes ELF-style $ORIGIN rpaths on the lslver binary.
    # Replace with macOS-native @loader_path so the binary can find liblsl.dylib.
    if OS.mac?
      file = MachO::MachOFile.new(bin/"lslver")
      file.rpaths.each { |rp| file.delete_rpath(rp) }
      file.add_rpath("@loader_path/../lib")
      file.write!
      # Re-sign: rpath edits invalidate the ad-hoc signature and the kernel
      # SIGKILLs the binary on launch (Apple Silicon hardened runtime).
      system "/usr/bin/codesign", "--force", "--sign", "-", bin/"lslver"
    end
  end

  test do
    (testpath/"test.c").write <<~C
      #include <lsl_c.h>
      int main() { return lsl_library_info() != 0 ? 0 : 1; }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-llsl", "-o", "test"
    system "./test"
    system bin/"lslver"
  end
end
