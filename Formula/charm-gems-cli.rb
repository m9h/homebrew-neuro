class CharmGemsCli < Formula
  desc "FSL-style CLI binaries for charm-gems (SimNIBS CHARM segmentation kernels)"
  homepage "https://github.com/m9h/charm-gems-cli"
  url "https://github.com/m9h/charm-gems-cli/archive/refs/heads/main.tar.gz"
  version "0.1.0"
  sha256 "e96b83634bdd66b37ce2e78c485177b3b4a488b77d47bb526b94bdfc272aeb1d"
  license "GPL-3.0-or-later"

  depends_on "python@3.13"
  depends_on "m9h/neuro/charm-gems"

  def install
    python3 = Formula["python@3.13"].opt_bin/"python3.13"
    
    # We use --no-deps because charm-gems is already installed via homebrew
    # and numpy should be managed either by the user or as a pip dep here.
    # To be safe and self-contained, we'll let pip ensure numpy is present.
    system python3, "-m", "pip", "install", "--prefix=#{prefix}", ".", "-v"
  end

  test do
    # Check if the binary was installed and can run
    assert_match "Usage: cgemsinfo", shell_output("#{bin}/cgemsinfo --help")
  end
end
