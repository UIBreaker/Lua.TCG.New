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
    vec2 offset=vec2(0.065+beat*0.025,0.006)*(0.9+u_hoverAmount*0.3+u_scorePulse*.3);
    vec4 ghost1=Texel(texture,clamp(uv-offset,vec2(0.0),vec2(1.0)))*color;
    vec4 ghost2=Texel(texture,clamp(uv-offset*2.0,vec2(0.0),vec2(1.0)))*color;
    number silhouette1=max(0.0,dot(ghost1.rgb-base.rgb,vec3(0.333)));
    number silhouette2=max(0.0,dot(ghost2.rgb-base.rgb,vec3(0.333)));
    silhouette1*=smoothstep(.12,.45,dot(ghost1.rgb,vec3(.333)));
    silhouette2*=smoothstep(.12,.45,dot(ghost2.rgb,vec3(.333)));
    // Two displaced curtains give Echo a horizontal silhouette, without a halo.
    number curve=sin(uv.y*3.14159)*.10;
    number edge1=abs(uv.x-(.21+curve+sin(t)*.025));
    number edge2=abs(uv.x-(.79-curve-sin(t)*.025));
    number envelope=sin(uv.y*3.14159);
    number curtain1=(exp(-edge1*170.0)*.36+exp(-edge1*26.0)*.09)*envelope;
    number curtain2=(exp(-edge2*170.0)*.24+exp(-edge2*26.0)*.07)*envelope;
    number streak=pow(.5+.5*sin(uv.y*44.0-t*2.0),12.0);
    vec3 rgb=base.rgb+vec3(.20,.85,1.0)*(silhouette1*1.80+curtain1)*u_intensity;
    rgb+=vec3(.55,.36,1.0)*(silhouette2*1.15+curtain2)*u_intensity;
    rgb+=vec3(.58,.93,1.0)*silhouette1*streak*.55*u_intensity;
    rgb=mix(rgb,ghost1.rgb*vec3(0.7,0.94,1.0),min(0.14,u_intensity*beat*0.10));
    return vec4(clamp(rgb,0.0,1.0),base.a);
}
