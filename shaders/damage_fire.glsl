// Steady combustion around a readable number, using the world's layered noise.
extern number clock;
extern number seed;
extern vec2 center;
extern vec2 halfSize;
extern number pixelScale;
extern number reach;
extern number energy;
extern vec3 accent;
extern number signature;
extern number chroma;

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
    vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float cloud(vec2 p) {
    return noise(p)*0.57+noise(p*2.03+17.1)*0.28+noise(p*4.11+31.7)*0.15;
}
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
    vec2 p=(screen-center)/max(pixelScale,0.01);
    float radius=min(halfSize.y,9.0);
    vec2 q=abs(p)-halfSize+radius;
    float rim=length(max(q,vec2(0.0)))+min(max(q.x,q.y),0.0)-radius;
    vec2 flow=p*vec2(0.085+mod(signature,2.0)*0.012,0.115)+vec2(seed+signature,clock*2.4);
    flow+=vec2(cloud(flow+7.0),cloud(flow-11.0))*(0.9+energy*1.4);
    float billow=cloud(flow);
    float fine=noise(flow*3.4+vec2(0.0,clock*1.1));
    // Buoyancy gives longer rising tongues while retaining fire along both sides and below.
    float buoyancy=mix(0.62,1.18,1.0-smoothstep(-halfSize.y,halfSize.y,p.y));
    float tongue=reach*buoyancy*(0.2+0.8*pow(billow,1.35-energy*0.5));
    float body=1.0-smoothstep(tongue-2.5,tongue+3.5,rim);
    float hollow=smoothstep(-5.0,-1.0,rim);
    float heat=clamp(1.0-max(rim,0.0)/max(tongue+2.0,1.0)+(fine-0.5)*0.24+energy*0.10,0.0,1.0);
    vec3 flame=mix(vec3(0.55,0.035,0.006),vec3(1.0,0.31,0.018),smoothstep(0.06,0.45,heat));
    flame=mix(flame,vec3(1.0,0.77,0.18),smoothstep(0.42,0.83,heat));
    flame=mix(flame,vec3(1.0,0.96,0.72),smoothstep(0.84,1.0,heat)*0.7);
    flame=mix(flame,accent*(0.35+heat*0.95),chroma*(1.0-smoothstep(0.72,1.0,heat)*0.6));
    float glow=exp(-max(rim,0.0)*0.12)*0.07;
    float alpha=hollow*(body*(0.48+billow*0.42)+glow);
    // The quad boundary fades fully; it must never become a visible rectangular plate.
    alpha*=1.0-smoothstep(reach+4.0,reach+9.0,rim);
    return vec4(flame,alpha)*color;
}
