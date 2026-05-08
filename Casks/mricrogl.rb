cask "mricrogl" do
  version "1.2.20220720"
  sha256 "3c979faecdb4113b6597458d5bd4bac7e0ded00c1fc5ec522d6d0fc8e57e9918"

  url "https://github.com/rordenlab/MRIcroGL/releases/download/v#{version}/MRIcroGL_macOS.dmg",
      verified: "github.com/rordenlab/MRIcroGL/"
  name "MRIcroGL"
  desc "3D visualization and analysis of medical imaging data"
  homepage "https://www.nitrc.org/projects/mricrogl/"

  depends_on macos: ">= :big_sur"

  app "MRIcroGL.app"

  zap trash: [
    "~/Library/Preferences/com.rordenlab.mricrogl.plist",
    "~/Library/Saved Application State/com.rordenlab.mricrogl.savedState",
  ]
end
