class Compucell3d < Formula
  desc "Multi-scale Virtual Tissue Modeling Environment"
  homepage "https://compucell3d.org/"
  url "https://github.com/CompuCell3D/CompuCell3D/archive/refs/tags/4.8.0.tar.gz"
  sha256 "ac53f05ab90bf85cbe8489fd68f3a9358df6d6007253786bdb2b4ae05f8320e4"
  license "MIT"

  depends_on "cmake" => :build
  depends_on "swig" => :build
  # CC3D ships a bundled FindEigen3.cmake that reads EIGEN_WORLD_VERSION,
  # which Eigen 5 removed. Pin to eigen@3 to keep the version probe happy.
  depends_on "eigen@3"
  depends_on "libomp"
  depends_on "numpy"
  depends_on "python@3.14"
  depends_on "qt@5"
  depends_on "tbb"
  depends_on "vtk"

  def install
    python3 = Formula["python@3.14"].opt_bin/"python3.14"
    libomp = Formula["libomp"]
    numpy_include = Formula["numpy"].opt_lib/"python3.14/site-packages/numpy/_core/include"
    eigen3_include = Formula["eigen@3"].opt_include/"eigen3"

    # Patch 1: macOS doesn't ship libgomp (GNU OpenMP). Use the CMake imported
    # target instead so the link resolves to Homebrew's libomp.
    inreplace "CompuCell3D/core/CompuCell3D/Potts3D/CMakeLists.txt",
              "SET(GOMP_LIB gomp)",
              "SET(GOMP_LIB OpenMP::OpenMP_CXX)"

    # Patch 2: libc++ removed std::unary_function in C++17. The inheritance
    # is only there for legacy typedefs that nothing in CC3D uses.
    inreplace "CompuCell3D/core/PublicUtilities/StringUtils.h",
              "class isWhiteSpaceFunctor: public std::unary_function<char,bool>{",
              "class isWhiteSpaceFunctor {"

    # Patch 3: NumPy 2 tightened the signatures of PyArray_DATA / NDIM / DIM /
    # TYPE / ISFLOAT / ISINTEGER / STRIDES / FLAGS / ITEMSIZE / SIZE etc. to
    # require PyArrayObject* rather than PyObject*. Add explicit casts at every
    # SWIG callsite.
    numpy_api_names = "DATA|NDIM|TYPE|STRIDES|FLAGS|ISFLOAT|ISINTEGER|" \
                      "ISCOMPLEX|ISBOOL|ISCONTIGUOUS|ITEMSIZE|SIZE"
    numpy_api_re = Regexp.new(
      "\\b(PyArray_(?:#{numpy_api_names}))\\s*" \
      "\\(((?:[^(),]|\\([^()]*\\))+)\\)",
    )
    numpy_dim_re = /\bPyArray_DIM\s*\(((?:[^(),]|\([^()]*\))+),/
    %w[
      CompuCell3D/core/pyinterface/CC3DAuxFields/CC3DAuxFields.i
      CompuCell3D/core/pyinterface/CompuCellPython/typemaps_CC3D.i
      CompuCell3D/core/pyinterface/FieldExtender/FieldExtender.i
      CompuCell3D/core/pyinterface/Fields/Fields.i
      CompuCell3D/core/pyinterface/Fields/typemaps_Fields.i
      CompuCell3D/core/pyinterface/PlayerPythonNew/PlayerPython.i
    ].each do |f|
      inreplace f do |s|
        s.gsub!(numpy_api_re, '\1((PyArrayObject*)(\2))') if numpy_api_re.match?(s.to_s)
        s.gsub!(numpy_dim_re, 'PyArray_DIM((PyArrayObject*)(\1),') if numpy_dim_re.match?(s.to_s)
      end
    end

    # Patch 4: SWIG 4.3 added a third `is_void` parameter to
    # SWIG_Python_AppendOutput. The bundled numpy.i was written for the
    # 2-arg form; append `,0` to every call.
    inreplace "CompuCell3D/core/pyinterface/swig_includes/numpy.i" do |s|
      s.gsub!("SWIG_Python_AppendOutput($result,(PyObject*)array$argnum);",
              "SWIG_Python_AppendOutput($result,(PyObject*)array$argnum,0);")
      s.gsub!("SWIG_Python_AppendOutput($result,obj);",
              "SWIG_Python_AppendOutput($result,obj,0);")
    end

    # Apple Clang ships without OpenMP; seed FindOpenMP with the Homebrew
    # libomp paths so CMake creates the OpenMP::OpenMP_CXX imported target.
    # Use Python3_EXECUTABLE (not legacy PYTHON_EXECUTABLE) so FindPython3
    # picks python@3.14 (matching the Python VTK was built against), and hint
    # Python3_NumPy_INCLUDE_DIR so it doesn't have to shell out to `import
    # numpy` at configure time.
    args = [
      "-DCMAKE_BUILD_TYPE=Release",
      "-DCMAKE_INSTALL_PREFIX=#{libexec}",
      "-DPython3_EXECUTABLE=#{python3}",
      "-DPython3_NumPy_INCLUDE_DIR=#{numpy_include}",
      "-DEIGEN3_INCLUDE_DIR=#{eigen3_include}",
      "-DBUILD_SHARED_LIBS=ON",
      "-DOpenMP_C_FLAGS=-Xpreprocessor -fopenmp -I#{libomp.opt_include}",
      "-DOpenMP_CXX_FLAGS=-Xpreprocessor -fopenmp -I#{libomp.opt_include}",
      "-DOpenMP_C_LIB_NAMES=omp",
      "-DOpenMP_CXX_LIB_NAMES=omp",
      "-DOpenMP_omp_LIBRARY=#{libomp.opt_lib}/libomp.dylib",
    ]

    # std_cmake_args sets CMAKE_INSTALL_PREFIX=#{prefix}; our -D above wins
    # because CMake honours the later value on the command line.
    system "cmake", "-S", "CompuCell3D", "-B", "build", *std_cmake_args, *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    # The _*.so Python extensions are linked with rpath `@loader_path/lib`,
    # but the install scatters dylibs across libexec/lib/, .../cpp/
    # CompuCell3DPlugins/, and .../cpp/CompuCell3DSteppables/. Stage symlinks
    # into cc3d/cpp/lib/ so the rpath resolves without rewriting any Mach-O
    # headers (which would invalidate the ad-hoc signature on Apple Silicon).
    cpp_lib = libexec/"lib/site-packages/cc3d/cpp/lib"
    cpp_lib.mkpath
    [
      libexec/"lib",
      libexec/"lib/site-packages/cc3d/cpp/CompuCell3DPlugins",
      libexec/"lib/site-packages/cc3d/cpp/CompuCell3DSteppables",
    ].each do |src|
      Pathname.glob("#{src}/*.dylib").each do |dylib|
        ln_sf dylib, cpp_lib/dylib.basename
      end
    end

    # CC3D's Python runtime has a bag of pure-Python deps (lxml, jinja2,
    # scipy, pandas, deprecated, psutil, ...) that aren't shipped with the
    # source tarball. Build a venv that inherits python@3.14's
    # site-packages — so it sees Homebrew's numpy + vtk Python bindings
    # without duplicating them — then pip-install the runtime extras into
    # the venv. The cc3d package itself is already at
    # libexec/lib/site-packages from the cmake install; expose it via
    # PYTHONPATH in the wrapper rather than copying it into the venv.
    venv_root = libexec/"venv"
    system python3, "-m", "venv", "--system-site-packages", venv_root
    venv_py = venv_root/"bin/python"
    system venv_py, "-m", "pip", "install", "--quiet", "--upgrade", "pip"
    system venv_py, "-m", "pip", "install", "--quiet",
                    "deprecated", "lxml", "jinja2", "psutil",
                    "scipy", "pandas"

    # Run CC3D headless simulations via `cc3d.run_script`. The Qt5 GUI player
    # (`cc3d.player5`) isn't built — that would need PyQt5 and additional
    # upstream wiring.
    (bin/"compucell3d").write <<~EOS
      #!/bin/bash
      export PYTHONPATH="#{libexec}/lib/site-packages:${PYTHONPATH}"
      exec "#{venv_py}" -m cc3d.run_script "$@"
    EOS
  end

  test do
    assert_path_exists bin/"compucell3d"
    # Smoke test: the cc3d package imports cleanly and the native modules load.
    venv_py = libexec/"venv/bin/python"
    ENV["PYTHONPATH"] = "#{libexec}/lib/site-packages"
    system venv_py, "-c",
           "import cc3d; from cc3d.cpp import CompuCell, PlayerPython; " \
           "import lxml, jinja2, scipy, pandas, deprecated, psutil"
  end
end
