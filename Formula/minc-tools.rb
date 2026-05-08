class MincTools < Formula
  desc "Basic command-line tools for MINC files"
  homepage "https://github.com/BIC-MNI/minc-tools"
  url "https://github.com/BIC-MNI/minc-tools/archive/e3825986359ecd75d82aa88ff2015d36e234e55d.tar.gz"
  version "2.3.2-20260106"
  sha256 "40a61818aaf8a4c40f580f867791a6e562fc6d962e0cb5c0fb5142d046406cf5"
  license "BSD-3-Clause"

  depends_on "bison" => :build
  depends_on "cmake" => :build
  depends_on "flex" => :build
  depends_on "hdf5"
  depends_on "libminc"
  depends_on "netcdf"

  def install
    # Fix C23 Standard Conflicts (NAN collision)
    inreplace "progs/minccalc/gram.y", /\bNAN\b/, "MINC_NAN"
    inreplace "progs/minccalc/lex.l", /\bNAN\b/, "MINC_NAN"

    # Fix C23/HDF5 Conflict (true/false keywords)
    inreplace "progs/mincdump/mincdump.h", /enum {false=0, true=1};/, ""

    # Rewrite conversion/CMakeLists.txt to disable broken NIfTI tools and fix acr_nema
    (buildpath/"conversion/CMakeLists.txt").write <<~EOS
      INCLUDE_DIRECTORIES(${LIBMINC_INCLUDE_DIRS} ${CMAKE_CURRENT_SOURCE_DIR}/Acr_nema)
      SET(ACR_SRCS
        Acr_nema/acr_io.c
        Acr_nema/dicom_client_routines.c
        Acr_nema/dicom_network.c
        Acr_nema/element.c
        Acr_nema/file_io.c
        Acr_nema/globals.c
        Acr_nema/group.c
        Acr_nema/message.c
        Acr_nema/value_repr.c
      )
      ADD_LIBRARY(acr_nema STATIC ${ACR_SRCS})
      ADD_EXECUTABLE(minctoecat
        minctoecat/minctoecat.c
        minctoecat/ecat_write.c
        minctoecat/machine_indep.c
      )
      TARGET_LINK_LIBRARIES(minctoecat acr_nema ${LIBMINC_LIBRARIES} m)
      ADD_EXECUTABLE(ecattominc
        ecattominc/ecattominc.c
        ecattominc/insertblood.c
        ecattominc/ecat_file.c
        ecattominc/machine_indep.c
      )
      TARGET_LINK_LIBRARIES(ecattominc ${LIBMINC_LIBRARIES})
      ADD_EXECUTABLE(upet2mnc micropet/upet2mnc.c)
      TARGET_LINK_LIBRARIES(upet2mnc ${LIBMINC_LIBRARIES})
      INSTALL(TARGETS minctoecat ecattominc upet2mnc DESTINATION bin)
    EOS

    # -std=gnu17 to avoid C23 keyword errors, -fcommon for legacy globals
    ENV.append "CFLAGS", "-std=gnu17 -fcommon"

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system "#{bin}/mincinfo", "--version"
  end
end
