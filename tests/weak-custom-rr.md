# Weak references to objects with custom retain/release

`weak-custom-rr.m` is a guest test (run inside Darling, both architectures). A
root class overrides `retain`/`release`, `allowsWeakReference` and
`retainWeakReference`; the test stores and loads a weak reference through
`objc_storeWeak()`/`objc_loadWeakRetained()` and checks that both methods are
consulted and that a refusal is honoured (`objc_storeWeakOrNil()` returns nil).

On i386 (legacy runtime) the lookups happen while the weak table lock is held;
they used to abort with "lock ... is incorrectly owned".

Build on the host with clang and the Darling ld64 (no guest compiler):

```sh
clang -target i386-apple-macos10.13 -isysroot <MacOSX.sdk> -B <dir with ld> \
      -o weak-custom-rr weak-custom-rr.m <path to libobjc.A.dylib>
```

(x86_64: `-target x86_64-apple-macos10.15 -D__DARWIN_ONLY_UNIX_CONFORMANCE=1`.)
Sign the result and run it with `darling shell`; it prints `PASS`.
