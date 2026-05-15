class Levmar < Formula
  desc "Levenberg-Marquardt nonlinear least squares (Lourakis)"
  homepage "https://users.ics.forth.gr/~lourakis/levmar/"
  url "https://users.ics.forth.gr/~lourakis/levmar/levmar-2.6.tgz"
  sha256 "3bf4ef1ea4475ded5315e8d8fc992a725f2e7940a74ca3b0f9029d9e6e94bad7"
  license "GPL-2.0-only"

  depends_on "cmake" => :build

  def install
    # levmar uses POSIX `finite()`, which Apple's Clang now refuses as an
    # implicit declaration (C99+). Map it to the standard `isfinite` macro
    # at the preprocessor level.
    ENV.append_to_cflags "-Dfinite=isfinite"

    # levmar's CMakeLists builds a static library only and does not provide
    # an install() rule. Build the library (skip the demo executable, which
    # is the only thing that would otherwise need a LAPACK at link time —
    # LAPACK is the consumer's concern for the static lib itself) and
    # install the artifacts manually. The CMakeLists predates CMake 3.5,
    # so bump the policy version to keep modern CMake happy.
    system "cmake", "-S", ".", "-B", "build",
                    "-DBUILD_DEMO=OFF",
                    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON",
                    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
                    *std_cmake_args
    system "cmake", "--build", "build"

    lib.install "build/liblevmar.a"
    include.install "levmar.h"
  end

  test do
    # Verify the static archive contains the expected entry symbol and that
    # the header is consumable by a minimal C program.
    (testpath/"check.c").write <<~C
      #include <levmar.h>
      int main(void) { return 0; }
    C
    system ENV.cc, "-I#{include}", "-c", "check.c", "-o", "check.o"
    output = shell_output("nm #{lib}/liblevmar.a")
    assert_match(/_dlevmar_der/, output)
  end
end
