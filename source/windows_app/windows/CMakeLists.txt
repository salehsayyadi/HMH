cmake_minimum_required(VERSION 3.14)
project(hmh_windows_app LANGUAGES CXX)

set(BINARY_NAME "hmh_windows_app")

cmake_policy(SET CMP0079 NEW)

# Add the Flutter library and tooling.
add_subdirectory(flutter)

add_subdirectory(runner)
