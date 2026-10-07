extern number u_time;
extern number u_intensity;
extern number u_speed;
extern number u_hoverAmount;
extern number u_scorePulse;
extern vec2 u_tilt;

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen_coords) {
    vec4 base=Texel(texture,uv)*color;
    if(base.a<=0.003) return vec4(0.0);
    number t=u_time*u_speed;
    number beat=0.5+0.5*sin(t*2.8);
    vec2 offset=vec2(0.032+beat*0.018,0.010)*(0.7+u_hoverAmount*0.5+u_scorePulse*.5);
    vec4 ghost1=Texel(texture,clamp(uv-offset,vec2(0.0),vec2(1.0)))*color;
    vec4 ghost2=Texel(texture,clamp(uv-offset*2.0,vec2(0.0),vec2(1.0)))*color;
    number silhouette1=max(0.0,dot(ghost1.rgb-base.rgb,vec3(0.333)));
    number silhouette2=max(0.0,dot(ghost2.rgb-base.rgb,vec3(0.333)));
    number r=length((uv-vec2(0.5))*vec2(1.0,1.5));
    number wave=exp(-pow(r-fract(t*0.35)*0.75,2.0)*1600.0);
    number halo=exp(-pow(r-fract(t*.35)*.75,2.0)*140.0);
    vec3 rgb=base.rgb+vec3(.22,.80,1.0)*(silhouette1*1.45+wave*.30+halo*.065)*u_intensity;
    rgb+=vec3(.50,.42,1.0)*silhouette2*.90*u_intensity;
    rgb=mix(rgb,ghost1.rgb*vec3(0.7,0.94,1.0),min(0.18,u_intensity*beat*0.12));
    return vec4(clamp(rgb,0.0,1.0),base.a);
}
