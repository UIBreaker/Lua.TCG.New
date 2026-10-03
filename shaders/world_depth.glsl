extern vec2 texel;
extern float radius;
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
    vec2 d = texel * radius;
    vec4 c = Texel(image, uv) * 0.28;
    c += (Texel(image, uv+vec2(d.x,0.0)) + Texel(image, uv-vec2(d.x,0.0))) * 0.12;
    c += (Texel(image, uv+vec2(0.0,d.y)) + Texel(image, uv-vec2(0.0,d.y))) * 0.12;
    c += (Texel(image, uv+d) + Texel(image, uv-d) + Texel(image, uv+vec2(d.x,-d.y)) + Texel(image, uv+vec2(-d.x,d.y))) * 0.06;
    return c * color;
}
