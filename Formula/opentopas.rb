class Opentopas < Formula
  desc "Monte Carlo tool for particle simulation in medical physics"
  homepage "https://opentopas.github.io/"
  url "https://github.com/OpenTOPAS/OpenTOPAS/archive/refs/tags/v4.2.3.tar.gz"
  sha256 "cd99d2f4f2e27e36092f823e8761b191148ccd9e30668c79eac274476483765a"
  license "GPL-3.0-or-later"

  depends_on "cmake" => :build
  depends_on "m9h/neuro/geant4"
  depends_on "qt"

  def install
    # Find Geant4 installation path
    geant4_dir = Formula["m9h/neuro/geant4"].opt_lib/"Geant4-#{Formula["m9h/neuro/geant4"].version}"

    args = %W[
      -DGeant4_DIR=#{geant4_dir}
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system "#{bin}/topas", "--version"
  end
end
