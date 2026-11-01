// imconfig.h options from upstream CI's "Build example_null (with
// IM_VEC2_CLASS_EXTRA and IM_VEC4_CLASS_EXTRA)" step (.github/workflows/build.yml).
struct MyVec2 { float x; float y; MyVec2(float x, float y) : x(x), y(y) { } };
struct MyVec4 { float x; float y; float z; float w;
MyVec4(float x, float y, float z, float w) : x(x), y(y), z(z), w(w) { } };
#define IM_VEC2_CLASS_EXTRA                                             \
        ImVec2(const MyVec2& f) { x = f.x; y = f.y; }                   \
        operator MyVec2() const { return MyVec2(x, y); }
#define IM_VEC4_CLASS_EXTRA                                             \
        ImVec4(const MyVec4& f) { x = f.x; y = f.y; z = f.z; w = f.w; } \
        operator MyVec4() const { return MyVec4(x, y, z, w); }
