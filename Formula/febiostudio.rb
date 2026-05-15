class Febiostudio < Formula
  desc "GUI environment for FEBio biomechanics simulations"
  homepage "https://febio.org/"
  url "https://github.com/febiosoftware/FEBioStudio/archive/refs/tags/v3.1.tar.gz"
  sha256 "abcd77c365b765dca29abde2a465890c54b94c1d813c0066aa5a9347099aa220"
  license "MIT"
  head "https://github.com/febiosoftware/FEBioStudio.git", branch: "develop"

  depends_on "cmake" => :build
  # PyLib's PythonRunner.cpp `#include`s pybind11 unconditionally — every
  # body that actually uses Python is `#ifdef HAS_PYTHON`-gated, but the
  # header includes are not. pybind11.h pulls in <Python.h>, so we can't
  # avoid a Python dependency even with USE_PYTHON=OFF. Just enable
  # USE_PYTHON=ON and let HAS_PYTHON be defined — that's the supported
  # configuration upstream.
  depends_on "pybind11" => :build
  # FEBioStudio's MPEGAnimation.cpp uses `avcodec_close`, removed in
  # FFmpeg 5.0. Pin to the keg-only ffmpeg@4 (4.4.x) which still has the
  # legacy API.
  depends_on "ffmpeg@4"
  depends_on "glew"
  depends_on "libomp"
  depends_on "libssh"
  depends_on "libzip"
  depends_on "m9h/neuro/febio"
  depends_on "m9h/neuro/mmg"
  depends_on "openssl@3"
  depends_on "python@3.14"
  depends_on "qt"
  depends_on "sqlite"

  uses_from_macos "zlib"

  def install
    febio = Formula["m9h/neuro/febio"]
    mmg = Formula["m9h/neuro/mmg"]
    qt = Formula["qt"]
    ffmpeg = Formula["ffmpeg@4"]
    libomp = Formula["libomp"]
    libssh_f = Formula["libssh"]

    # FEBioStudio walks Qt_Root/* to find Qt6Config.cmake. Homebrew's qt
    # ships it at <prefix>/lib/cmake/Qt6, so passing Qt_Root=#{qt.opt_prefix}
    # plus the standard CMAKE_PREFIX_PATH is enough.
    pybind11 = Formula["pybind11"]
    python = Formula["python@3.14"]

    args = [
      "-DCMAKE_BUILD_TYPE=Release",
      "-DCMAKE_INSTALL_PREFIX=#{libexec}",
      "-DQt_Root=#{qt.opt_prefix}",
      "-DCMAKE_PREFIX_PATH=#{qt.opt_prefix};#{febio.opt_prefix};#{pybind11.opt_prefix}",
      "-DUSE_PYTHON=ON",
      "-DPYBIND11_INC=#{pybind11.opt_include}",
      "-DPython3_EXECUTABLE=#{python.opt_bin}/python3.14",
      "-DUSE_MMG=ON",
      "-DMMG_INC=#{mmg.opt_include}",
      "-DMMG_LIB_DIR=#{mmg.opt_lib}",
      "-DUSE_SSH=ON",
      "-DSSH_INC=#{libssh_f.opt_include}",
      "-DSSH_LIB_DIR=#{libssh_f.opt_lib}",
      "-DUSE_FFMPEG=ON",
      "-DFFMPEG_INC=#{ffmpeg.opt_include}",
      "-DFFMPEG_LIB_DIR=#{ffmpeg.opt_lib}",
      # Homebrew ships Qt 6.11, which lives past the 6.10 cutoff that
      # FEBioStudio gates GuiPrivate detection on. The CMakeLists still
      # unconditionally links Qt6::GuiPrivate, so we have to flip this
      # explicitly to make the find_package call run.
      "-DQT_6_10=ON",
      "-DUSE_ZLIB=ON",
      "-DUSE_ITK=OFF",
      "-DCAD_FEATURES=OFF",
      "-DUSE_TETGEN=OFF",
      "-DBUILD_UPDATER=OFF",
      "-DBUILD_TESTS=OFF",
      "-DMODEL_REPO=ON",
      "-DOMP_INC=#{libomp.opt_include}",
      "-DCMAKE_EXE_LINKER_FLAGS=-L#{libomp.opt_lib} -lomp",
      "-DCMAKE_SHARED_LINKER_FLAGS=-L#{libomp.opt_lib} -lomp",
    ]

    system "cmake", "-S", ".", "-B", "cmbuild", *std_cmake_args, *args
    system "cmake", "--build", "cmbuild"

    # FEBioStudio's CMakeLists has no install() rule; the build emits
    # FEBioStudio.app under cmbuild/bin/. Stage it under libexec, drop the
    # febio4 CLI from the FEBio formula into Contents/MacOS and its dylibs
    # into Contents/Frameworks (matches postBuild.sh's release layout), then
    # link the .app into /Applications/ via a normal bundle install.
    prefix.install "cmbuild/bin/FEBioStudio.app"
    macos_dir = prefix/"FEBioStudio.app/Contents/MacOS"
    frameworks_dir = prefix/"FEBioStudio.app/Contents/Frameworks"
    frameworks_dir.mkpath

    cp febio.opt_bin/"febio4", macos_dir
    Pathname.glob("#{febio.opt_lib}/*.dylib").each do |dylib|
      cp dylib, frameworks_dir
    end

    # Run Qt's macdeployqt to bundle Qt frameworks + plugins into the .app
    # so it works from /Applications without DYLD_FRAMEWORK_PATH gymnastics.
    system qt.opt_bin/"macdeployqt", prefix/"FEBioStudio.app"

    # Symlink an `febiostudio` launcher CLI onto PATH for headless-friendly
    # integration test discovery.
    (bin/"febiostudio").write <<~EOS
      #!/bin/bash
      exec "#{prefix}/FEBioStudio.app/Contents/MacOS/FEBioStudio" "$@"
    EOS
  end

  def caveats
    <<~EOS
      FEBioStudio.app is installed under #{prefix}. To launch it from
      Finder, symlink it into ~/Applications:

        ln -sf #{prefix}/FEBioStudio.app ~/Applications/FEBioStudio.app

      A CLI launcher is on PATH as `febiostudio`.

      This build omits SimpleITK image import (no SimpleITK formula in
      Homebrew), TetGen meshing, and NetGen-based CAD features.
    EOS
  end

  test do
    assert_path_exists prefix/"FEBioStudio.app/Contents/MacOS/FEBioStudio"
    assert_path_exists bin/"febiostudio"
  end
end
