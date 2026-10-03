extern number dissolveAmount;
extern number crackAmount;
extern number flashAmount;
extern vec3 emberColor;
extern vec3 crackGlowColor;
number hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
number noise(vec2 p) {
    vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
    vec4 base=Texel(image,uv);
    if(base.a<0.001 || dissolveAmount>=1.0) return vec4(0.0);
    number field=0.60*noise(uv*13.0)+0.25*noise(uv*36.0)+0.15*(1.0-uv.y);
    number threshold=dissolveAmount*1.15-0.08;
    number mask=smoothstep(threshold,threshold+0.035,field);
    number edge=(1.0-smoothstep(threshold+0.025,threshold+0.095,field))*mask;
    number cracks=pow(1.0-abs(sin((uv.x*1.4+uv.y+noise(uv*8.0)*0.7)*32.0)),18.0);
    base.rgb=mix(base.rgb,crackGlowColor,clamp(cracks*crackAmount+flashAmount,0.0,1.0));
    base.rgb=mix(base.rgb,emberColor,edge*0.9);
    return vec4(base.rgb,base.a*mask)*color;
}
