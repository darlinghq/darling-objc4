// Host harness for validateAlreadyRealizedClass(), whose body the runner cuts
// out of runtime/objc-runtime-new.mm into VALIDATE_SOURCE. The allocator is a
// stub whose malloc_size() result each case chooses.
#include <cassert>
#include <cstdint>
#include <cstdio>
#include <cstddef>

#define TARGET_OS_OSX 1
#define ASSERT(x) assert(x)

// Same members as the 64-bit class_rw_t without SUPPORT_INDEXED_ISA.
struct class_rw_t {
    uint32_t flags;
    uint16_t witness;
    uintptr_t ro_or_rw_ext;
    void *firstSubclass;
    void *nextSiblingClass;
};

struct objc_class {
    class_rw_t *rw;
    bool isRealized() const { return true; }
    class_rw_t *data() const { return rw; }
};
typedef objc_class *Class;

static size_t reported_size;
static size_t malloc_size(const void *) { return reported_size; }

struct fatal_error {};
[[noreturn]] static void _objc_fatal(const char *, ...) { throw fatal_error(); }

#include VALIDATE_SOURCE

static bool aborts_with(size_t size)
{
    class_rw_t rw = {};
    objc_class cls = { &rw };
    reported_size = size;
    try {
        validateAlreadyRealizedClass(&cls);
    } catch (fatal_error &) {
        return true;
    }
    return false;
}

int main()
{
    int failures = 0;
    struct { size_t size; bool aborts; const char *what; } cases[] = {
        { sizeof(class_rw_t), false, "exact size" },
        { sizeof(class_rw_t) + 16, false, "allocator rounded up to a larger bucket" },
        { sizeof(class_rw_t) - 8, true, "block smaller than class_rw_t" },
        { 0, true, "pointer not from malloc" },
    };
    for (auto &c : cases) {
        bool got = aborts_with(c.size);
        if (got != c.aborts) {
            printf("FAIL: malloc_size %zu (%s): %s\n", c.size, c.what,
                   got ? "_objc_fatal called" : "accepted");
            failures++;
        }
    }
    if (failures)
        return 1;
    printf("PASS: class_rw_t malloc_size validation\n");
    return 0;
}
