class Labrecorder < Formula
  desc "Record and write Lab Streaming Layer streams to XDF files"
  homepage "https://github.com/labstreaminglayer/App-LabRecorder"
  url "https://github.com/labstreaminglayer/App-LabRecorder/archive/refs/tags/v1.17.1.tar.gz"
  sha256 "ef2f95e60be60494138a323e2aa566c5dea9bd6eac4ff889f921e0a155e64222"
  license "MIT"

  depends_on "cmake" => :build
  depends_on "mhough/neuro/liblsl"
  depends_on "qt"

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build", "--parallel", ENV.make_jobs
    bin.install "build/LabRecorderCLI"
    prefix.install "build/LabRecorder.app"
    bin.install_symlink prefix/"LabRecorder.app/Contents/MacOS/LabRecorder"
  end

  test do
    assert_match "Usage", shell_output("#{bin}/LabRecorderCLI --help 2>&1", 1)
  end
end
