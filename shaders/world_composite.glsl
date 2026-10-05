extern Image bloomTexture;
extern float bloomStrength;
extern vec3 grade;
extern vec3 ambient;
extern float vignette;
extern float dim;
extern float crtStrength;
extern vec2 waveCenter;
extern float waveRadius;
extern float waveStrength;
extern float waveAspect;
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
    vec2 delta=(uv-waveCenter)*vec2(1280.0,720.0);
    float distanceToWave=length(delta*vec2(1.0,waveAspect));
    float band=exp(-pow((distanceToWave-waveRadius)/10.0,2.0));
    vec2 warp=normalize(delta+vec2(0.001))*band*waveStrength;
    vec4 base=Texel(image,clamp(uv+warp,0.0,1.0));
    vec3 c=base.rgb*ambient*grade*(1.0-dim);
    c+=Texel(bloomTexture,uv).rgb*bloomStrength;
    vec2 q=(uv-0.5)*vec2(1.0,0.72);
    c*=1.0-vignette*smoothstep(0.20,0.60,length(q));
    c*=1.0-crtStrength*(0.5+0.5*sin(screen.y*3.14159));
    return vec4(clamp(c,0.0,1.0),base.a)*color;
}
