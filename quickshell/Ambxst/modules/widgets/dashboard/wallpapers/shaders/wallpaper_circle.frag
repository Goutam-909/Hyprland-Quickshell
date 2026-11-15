#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;   // 0 = only fromImage, 1 = only toImage
    float aspect;     // width / height
    vec2 origin;      // circle centre, 0..1
    float softness;   // feather width (in height units)
} ubuf;

layout(binding = 1) uniform sampler2D fromImage;
layout(binding = 2) uniform sampler2D toImage;

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 k = vec2(ubuf.aspect, 1.0);
    float d = length((uv - ubuf.origin) * k);
    float maxD = length(max(ubuf.origin, 1.0 - ubuf.origin) * k);
    float r = ubuf.progress * (maxD + ubuf.softness);
    float m = 1.0 - smoothstep(r - ubuf.softness, r, d);
    vec4 a = texture(fromImage, uv);
    vec4 b = texture(toImage, uv);
    fragColor = mix(a, b, m) * ubuf.qt_Opacity;
}
