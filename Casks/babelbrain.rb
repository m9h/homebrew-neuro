cask "babelbrain" do
  arch arm: "ARM64", intel: "Intel64"

  version "0.8.0"
  sha256 arm:   "f9958337f92a38f25ed251e67e2e277d6423fe09a2cbfe5742436f0219474f44",
         intel: "e7bd5f68e32226395c23f620e196e0874af1f68011b0b6515e9e63a4c0b25e58"

  url "https://github.com/ProteusMRIgHIFU/BabelBrain/releases/download/#{version}/BabelBrain_#{arch}.dmg"
  name "BabelBrain"
  desc "Modeling of transcranial focused ultrasound"
  homepage "https://github.com/ProteusMRIgHIFU/BabelBrain"

  livecheck do
    url :url
    strategy :github_releases
  end

  pkg "BabelBrain_#{arch}.pkg"

  uninstall pkgutil: "com.proteusmrig.BabelBrain"

  zap trash: [
    "~/Library/Preferences/com.proteusmrig.BabelBrain.plist",
    "~/Library/Saved Application State/com.proteusmrig.BabelBrain.savedState",
  ]
end
