# Fragile base class: subclass without ivars

Guest test for the legacy (32-bit) runtime, in `tests/fragile-subclass-size/`. It needs a Darling
prefix and an i386 compiler setup (the 32-bit runtime is only used by i386 binaries); it is not
built by the runtime's build.

`base.m` builds a library with a base class `FragileBase` that has five int ivars. `main.m` is
compiled with `-DBASE_V1`, which makes `base.h` declare only one ivar, as an older version of the
library did, so its subclass `Sub` (no ivars of its own) records an instance size for the small
base class. The test checks that `Sub` instances are at least as large as the real base class,
that the base class's ivars are usable in a `Sub`, and that neighbouring heap blocks are not
overwritten.

```sh
clang -arch i386 -dynamiclib -install_name @rpath/libfragile.dylib -framework Foundation \
    -o libfragile.dylib tests/fragile-subclass-size/base.m
clang -arch i386 -DBASE_V1 -Itests/fragile-subclass-size -framework Foundation -L. -lfragile \
    -Wl,-rpath,@executable_path -o fragile tests/fragile-subclass-size/main.m
./fragile
```

Covered: a subclass that has no ivars of its own. A subclass that adds ivars keeps the offsets
compiled into it and is not fixed by the runtime.
