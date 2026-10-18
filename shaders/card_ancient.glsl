extern number u_time;
extern number u_intensity;
extern number u_speed;
extern number u_scorePulse;
extern number u_hoverAmount;

number segment(vec2 p,vec2 a,vec2 b) {
    vec2 v=b-a;
    return length(p-a-v*clamp(dot(p-a,v)/dot(v,v),0.0,1.0));
}
vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen_coords) {
    vec4 base=Texel(texture,uv)*color;
    if(base.a<=0.003) return vec4(0.0);
    number line=segment(uv,vec2(.5,.83),vec2(.5,.20));
    for(int i=0;i<3;i++) {
        number y=.31+float(i)*.16;
        line=min(line,segment(uv,vec2(.5,y+.12),vec2(.25,y)));
        line=min(line,segment(uv,vec2(.5,y+.12),vec2(.75,y)));
    }
    // Angular stone channels: a white-hot core with a soft amber wake.
    line=min(line,segment(uv,vec2(.25,.31),vec2(.25,.63)));
    line=min(line,segment(uv,vec2(.75,.31),vec2(.75,.63)));
    number carved=exp(-line*180.0);
    number halo=exp(-line*38.0);
    number cycle=fract(u_time*u_speed*.60);
    number wake=exp(-pow(uv.y-(.80-cycle*.60),2.0)*65.0)*sin(cycle*3.14159);
    number etching=sin(uv.x*340.0+sin(uv.y*19.0)*8.0)*.018;
    number cracks=abs(sin(uv.x*21.0+sin(uv.y*23.0)*.8));
    number roots=exp(-cracks*50.0)*exp(-line*18.0)*wake;
    number motes=0.0;
    for(int i=0;i<4;i++) {
        number seed=float(i);
        number life=fract(u_time*u_speed*.22+seed*.27);
        vec2 pos=vec2(.34+seed*.105+sin(u_time*.6+seed)*.016,.82-life*.57);
        vec2 delta=(uv-pos)*vec2(1.0,1.5);
        motes+=exp(-dot(delta,delta)*6500.0)*sin(life*3.14159);
    }
    vec3 rgb=mix(base.rgb,base.rgb*vec3(.90,1.03,.90),min(.26,u_intensity*.18));
    rgb+=base.rgb*etching*u_intensity;
    number power=.72+wake*.55+u_scorePulse*.35+u_hoverAmount*.12;
    rgb+=vec3(.16,.90,.38)*(carved*.68+halo*.22)*power*u_intensity;
    rgb+=vec3(.90,1.0,.66)*carved*wake*.60*u_intensity;
    rgb+=vec3(.47,.85,.24)*roots*.34*u_intensity;
    rgb+=vec3(.75,1.0,.50)*motes*.65*u_intensity;
    return vec4(clamp(rgb,0.0,1.0),base.a);
}
