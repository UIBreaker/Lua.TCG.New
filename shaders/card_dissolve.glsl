extern number dissolveAmount;
extern number time;
extern vec3 edgeColor;

number hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
number noise(vec2 p) {
    vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1.0,0.0)),f.x),
               mix(hash(i+vec2(0.0,1.0)),hash(i+vec2(1.0,1.0)),f.x),f.y);
}
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
    vec4 base=Texel(image,uv);
    if (base.a < 0.001 || dissolveAmount >= 1.0) return vec4(0.0);
    number field=0.72*noise(uv*9.0+vec2(time*0.05,0.0)) + 0.28*noise(uv*24.0);
    number threshold=dissolveAmount*1.12-0.06;
    number mask=smoothstep(threshold,threshold+0.045,field);
    number edge=(1.0-smoothstep(threshold+0.025,threshold+0.11,field))*mask;
    // The reusable card canvas is premultiplied: edge light must be too.
    base.rgb=mix(base.rgb,edgeColor*base.a,edge*0.80);
    return base*mask*color;
}
