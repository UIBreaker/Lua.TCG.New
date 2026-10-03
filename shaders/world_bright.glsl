extern float threshold;
extern float knee;
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
    vec3 c=Texel(image,uv).rgb;
    float lum=max(c.r,max(c.g,c.b));
    float weight=smoothstep(threshold-knee,threshold+knee,lum);
    return vec4(c*weight,1.0)*color;
}
