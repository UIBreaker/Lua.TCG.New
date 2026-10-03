extern vec2 direction;
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
    vec4 c=Texel(image,uv)*0.227027;
    c+=(Texel(image,uv+direction*1.384615)+Texel(image,uv-direction*1.384615))*0.316216;
    c+=(Texel(image,uv+direction*3.230769)+Texel(image,uv-direction*3.230769))*0.070270;
    return c*color;
}
