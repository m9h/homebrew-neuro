class Quit < Formula
  desc "Quantitative Imaging Tools for MRI data processing"
  homepage "https://github.com/spinicist/QUIT"
  url "https://github.com/spinicist/QUIT/archive/refs/tags/v3.4.tar.gz"
  sha256 "cda9c6b744e399e34989c5f962eb5129a92c04a964b013fa6d9d50c568406bc6"
  license "MPL-2.0"

  depends_on "cmake" => :build
  depends_on "ceres-solver"
  depends_on "eigen"
  depends_on "itk-neuro"
  depends_on "nlohmann-json"
  depends_on "suite-sparse"

  # QUIT 3.4 is incompatible with fmt 11, so we bundle 9.1.0
  resource "fmt" do
    url "https://github.com/fmtlib/fmt/archive/refs/tags/9.1.0.tar.gz"
    sha256 "5dea48d1fcddc3ec571ce2058e13910a0d4a6bab4cc09a809d8b1dd1c88ae6f2"
  end

  # args is a header-only library not always available in homebrew-core
  resource "args" do
    url "https://github.com/Taywee/args/archive/refs/tags/6.4.8.tar.gz"
    sha256 "52ecaceb92c3865c8a210091f288b4902e0a08280327a80c4b8d8aec5d7a3bbe"
  end

  def install
    # Setup bundled resources
    resource("args").stage do
      (buildpath/"External/include").install "args.hxx"
    end

    resource("fmt").stage do
      system "cmake", "-S", ".", "-B", "build", "-DFMT_DOC=OFF", "-DFMT_TEST=OFF",
             *std_cmake_args(install_prefix: buildpath/"External/fmt/install")
      system "cmake", "--build", "build"
      system "cmake", "--install", "build"
    end

    # Create a simple Findargs.cmake as it's missing from the source but required by the build
    (buildpath/"cmake/Findargs.cmake").write <<~EOS
      find_path(args_INCLUDE_DIR NAMES args.hxx PATHS "${External_Include_DIR}")
      include(FindPackageHandleStandardArgs)
      find_package_handle_standard_args(args DEFAULT_MSG args_INCLUDE_DIR)
      if(args_FOUND)
        set(args_INCLUDE_DIRS ${args_INCLUDE_DIR})
        if(NOT TARGET args::args)
          add_library(args::args INTERFACE IMPORTED)
          set_target_properties(args::args PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${args_INCLUDE_DIRS}")
        endif()
      endif()
    EOS

    # Patch for GCC 13+ / C++20 and fmt 9 compatibility (from species spec)
    inreplace "Source/Sequences/SSFPSequence.h" do |s|
      s.gsub!(/template <typename FormatContext>.*};/m, <<~CPP)
        template <typename FormatContext> auto format(const QI::SSFPSequence &s, FormatContext &ctx) const {
          std::ostringstream oss;
          oss << "SSFP:\\n\\tTR: " << s.TR << "\\n\\tFA: " << (s.FA * 180. / M_PI).transpose()
              << "\\n\\tPhaseInc: " << (s.PhaseInc * 180. / M_PI).transpose();
          return fmt::format_to(ctx.out(), "{}", oss.str());
        }
        };
      CPP
      s.prepend "#include <sstream>\n"
    end

    # Ensure cstdint is included for uint8_t
    Dir.glob("Source/**/*.h").each do |f|
      content = File.read(f)
      if content.include?("uint8_t") && content.exclude?("<cstdint>")
        File.open(f, "w") { |file| file.puts "#include <cstdint>\n" + content }
      end
    end

    args = %W[
      -DCMAKE_MODULE_PATH:PATH=#{buildpath}/cmake
      -DExternal_Include_DIR:PATH=#{buildpath}/External/include
      -DBUILD_PARMESAN:BOOL=OFF
      -Dfmt_DIR:PATH=#{buildpath}/External/fmt/install/lib/cmake/fmt
    ]

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    # Check if the binary was installed and can run
    assert_match "qi", shell_output("#{bin}/qi --help")
  end
end
