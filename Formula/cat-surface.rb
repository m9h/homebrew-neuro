class CatSurface < Formula
  desc "Cortex Analysis Tools for Surface (CAT12 backend, used by T1Prep)"
  homepage "https://github.com/ChristianGaser/CAT-Surface"
  url "https://github.com/ChristianGaser/CAT-Surface/archive/refs/tags/v1.0.2.tar.gz"
  sha256 "8998db609277b6eb0b096b2e2fc0379dac9c2f2633d85515b981b15569bf75db"
  license "GPL-3.0-only"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build

  def install
    # autogen.sh calls `libtoolize`, but Homebrew's libtool only installs
    # `glibtoolize` on macOS. Shim it onto PATH so autogen.sh succeeds.
    bin_shim = buildpath/"shim"
    bin_shim.mkpath
    (bin_shim/"libtoolize").write <<~EOS
      #!/bin/sh
      exec glibtoolize "$@"
    EOS
    chmod 0755, bin_shim/"libtoolize"
    ENV.prepend_path "PATH", bin_shim

    # autogen.sh forwards remaining args to configure.
    system "./autogen.sh", "--prefix=#{prefix}",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules"
    system "make", "-j#{ENV.make_jobs}"
    system "make", "install"
  end

  test do
    # CAT_SurfArea (and most CAT_* tools) print a usage banner and exit 1
    # when called without the required surface argument.
    output = shell_output("#{bin}/CAT_SurfArea 2>&1", 1)
    assert_match "Usage", output
    assert_match "CAT_SurfArea", output
  end
end
