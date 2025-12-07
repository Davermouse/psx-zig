This is an attempt to follow on from some work to write code for PSX using Zig, built the fine work at https://github.com/XaviDCR92/psx-zig.

I've updated the project to use the latest Zig version (https://codeberg.org/ziglang/zig/commit/bfe3317059131ab552f7583b88d6bc82609d198c). I've had to build this from source with a custom LLVM version to fix the MIPS 1 support, based on the patch at at https://github.com/simias/psx-sdk-rs/issues/1.

## Build

To build a compiler suitable for use with this, following the Zig build instructions at https://codeberg.org/ziglang/zig#building-llvm-lld-and-clang-from-source, but after downloading the LLVM source apply the patch at (diffs/llvm-project-21-mips-1.diff).

This fixes the use of sync instructions on Mips 1, and removes an error message which Zig treats as an error.

