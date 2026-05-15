cask "babelbrain" do
  arch arm: "arm64", intel: "x64"

  version "0.8.1"
  sha256 arm:   "611da6a721089bf7c9dc30ae6ea80a5c16160ded68ac3613152ae77288de6d3b",
         intel: "d74114fd8ac3d963f4248b567d3194c074a4ec23b9c1706506f1aa538554335e"

  url "https://github.com/ProteusMRIgHIFU/BabelBrain/releases/download/v#{version}/" \
      "BabelBrain-macOS-#{arch}.dmg"
  name "BabelBrain"
  desc "Modeling of transcranial focused ultrasound"
  homepage "https://github.com/ProteusMRIgHIFU/BabelBrain"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :ventura

  pkg "BabelBrain.pkg"

  # BabelBrain's installer is a Distribution pkg whose outer wrapper has
  # the anonymous identifier `pkg_root` (the inner bundle id
  # com.ucalgary.babelbrain is metadata, not a pkg receipt). Target the
  # outer id for receipt cleanup, and rely on delete: for the .app itself.
  uninstall pkgutil: "pkg_root",
            delete:  "/Applications/BabelBrain.app"

  zap trash: [
    "~/Library/Preferences/com.ucalgary.babelbrain.plist",
    "~/Library/Saved Application State/com.ucalgary.babelbrain.savedState",
  ]
end
