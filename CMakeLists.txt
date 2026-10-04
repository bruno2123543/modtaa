cmake_minimum_required(VERSION 3.20)
cmake_policy(SET CMP0091 NEW)
project(w3_taa CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_SHARED_LIBRARY_PREFIX "")
# Runtime estatico: a DLL nao depende do VC++ Redistributable
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded")

include(FetchContent)
FetchContent_Declare(minhook
  GIT_REPOSITORY https://github.com/TsudaKageyu/minhook.git
  GIT_TAG        master)
FetchContent_MakeAvailable(minhook)

add_library(dxgi SHARED src/dllmain.cpp src/dxgi.def)
# Link com as libs de import do d3d11/d3dcompiler, mas NAO com dxgi.lib
# (nossa propria DLL se chama dxgi).
target_link_libraries(dxgi PRIVATE minhook d3d11 d3dcompiler)
target_compile_definitions(dxgi PRIVATE WIN32_LEAN_AND_MEAN NOMINMAX)
