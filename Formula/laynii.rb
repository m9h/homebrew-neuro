class Laynii < Formula
  desc "Suite of C++ programs for layer-fMRI neuroimaging analysis"
  homepage "https://github.com/layerfMRI/LAYNII"
  url "https://github.com/layerfMRI/LAYNII/archive/refs/tags/v2.10.0.tar.gz"
  sha256 "9b1647fbe97816b199fb2449c19c04380f0c4a20c835eca3c6a57c0dbfe96830"
  license "BSD-3-Clause"

  depends_on "make" => :build
  depends_on "sdl2"
  depends_on "zlib"

  def install
    # Use Homebrew compiler and linker flags
    inreplace "Makefile" do |s|
      s.gsub!(/^CFLAGS\t*=.*-std=c++11 -DHAVE_ZLIB/, "CFLAGS = #{ENV.cflags} -std=c++11 -DHAVE_ZLIB")
      s.gsub!(/^CFLAGS.*+=.*-O3/, "")
      s.gsub!(/^LFLAGS\t*=.*/, "LFLAGS = #{ENV.ldflags} -lm -lz")
    end

    # Apply flags to IDA GUI Makefile
    inreplace "ida/src/Makefile" do |s|
      s.gsub!(/^CXXFLAGS = -std=c++11/, "CXXFLAGS = #{ENV.cxxflags} -std=c++11")
      s.gsub!(/^CXXFLAGS \+= -O3/, "")
      s.gsub!(/^CXXFLAGS \+= -g -Wall -Wformat/,
              "CXXFLAGS += -g -Wall -Wformat -Wno-error=format-security -Wno-format-zero-length")
    end

    # Build CLI tools
    system "make"

    # Build IDA GUI application
    system "make", "-C", "ida/src", "LayNii_IDA"

    # Install CLI tools
    bin.install Dir["LN_*"], Dir["LN2_*"]

    # Install IDA GUI
    bin.install "ida/src/LayNii_IDA"

    # Install logo
    (share/"icons/hicolor/scalable/apps").install "visuals/LayNii_logo.svg" => "laynii.svg"
  end

  test do
    system "#{bin}/LN_INFO", "--help"
  end
end
