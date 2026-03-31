class Laynii < Formula
  desc "Package of standalone layer fMRI C++ programs"
  homepage "https://github.com/layerfMRI/LAYNII"
  url "https://github.com/layerfMRI/LAYNII/archive/refs/tags/v2.10.0.tar.gz"
  sha256 "9b1647fbe97816b199fb2449c19c04380f0c4a20c835eca3c6a57c0dbfe96830"
  license "BSD-3-Clause"

  depends_on "zlib"

  def install
    system "make", "-j#{ENV.make_jobs}", "all"

    # Install all LN_* and LN2_* binaries
    Dir["LN_*", "LN2_*"].each do |f|
      bin.install f if File.executable?(f) && !File.directory?(f)
    end
  end

  test do
    assert_match "Displays the basic features", shell_output("#{bin}/LN_INFO 2>&1")
  end
end
