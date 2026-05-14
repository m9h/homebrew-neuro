cask "copasi" do
  arch arm: "arm", intel: "intel"

  version "4.46,300"
  sha256 arm:   "0c044f9c0c14c49f65478a9bdf8865b291628f09a14973fc7ce5e212f18248a4",
         intel: "75242a138de1e3eb0061a1a3d83686fcd68af36e95d06879fa1314a37657f1de"

  url "https://github.com/copasi/COPASI/releases/download/Build-#{version.csv.second}/" \
      "COPASI-#{version.csv.first}.#{version.csv.second}-Darwin-#{arch}.dmg",
      verified: "github.com/copasi/COPASI/"
  name "COPASI"
  desc "Simulation and analysis of biochemical networks"
  homepage "https://copasi.org/"

  livecheck do
    url :url
    strategy :github_latest
    regex(/^Build-(\d+)$/i)
  end

  depends_on macos: :monterey

  app "COPASI/CopasiUI.app"
  binary "COPASI/CopasiSE"

  zap trash: [
    "~/.copasi",
    "~/Library/Preferences/org.copasi.CopasiUI.plist",
    "~/Library/Saved Application State/org.copasi.CopasiUI.savedState",
  ]
end
