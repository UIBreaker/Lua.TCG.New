// Original procedural combustion; cached at startup, world pass only.
extern float phase;
extern float seed;
extern vec3 fireColor;
extern vec3 coreColor;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float cloud(vec2 p) {
 return noise(p)*0.57+noise(p*2.03+17.1)*0.28+noise(p*4.11+31.7)*0.15;
}
vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
 vec2 p=(uv-.5)*2.0;
 p.y+=.20*phase;
 float angle=atan(p.y,p.x);
 float growth=.22+.68*(1.0-exp(-phase*8.0));
 vec2 flow=p*4.5+vec2(seed,phase*1.8);
 float billow=cloud(flow);
 float rim=length(p)-growth*(.92+.08*sin(angle*5.0+seed)+.055*sin(angle*9.0-seed))-(billow-.5)*.30;
 float alpha=(1.0-smoothstep(-.055,.055,rim))*(1.0-smoothstep(.58,1.0,phase));
 float inner=1.0-smoothstep(-.24,-.015,rim);
 float detail=noise(flow*3.1+vec2(phase*2.0,-phase));
 float heat=clamp(billow*1.65+detail*.20-.58+inner*.26-phase*.42,0.0,1.0);
 heat+=exp(-dot(p,p)*16.0)*(1.0-phase)*.22;
 vec3 soot=vec3(.11,.045,.025);
 vec3 flame=mix(soot,fireColor*1.15,smoothstep(.08,.56,heat));
 flame=mix(flame,coreColor*1.25,smoothstep(.64,.98,heat));
 // Large turbulent pockets rather than polygon wedges or uniform radial dots.
 alpha*=.85+.15*billow;
 return vec4(flame,alpha)*color;
}
