# class_rw_t malloc_size check

`run-class-rw-malloc-size.sh` cuts `validateAlreadyRealizedClass()` out of
`runtime/objc-runtime-new.mm` and builds it on the host against stubs for
`malloc_size()` and `_objc_fatal()`. No Darling build is needed:

```sh
bash tests/run-class-rw-malloc-size.sh
CXX="zig c++" bash tests/run-class-rw-malloc-size.sh
```

It checks that a `class_rw_t` block whose `malloc_size()` equals or exceeds
`sizeof(class_rw_t)` is accepted and that a smaller one, or a pointer malloc
does not know (size 0), reaches `_objc_fatal`. The `class_rw_t` in the harness
has the 64-bit members, not the real type, so it does not check the runtime's
own layout. It does not exercise realization, the runtime lock or a real zone.
