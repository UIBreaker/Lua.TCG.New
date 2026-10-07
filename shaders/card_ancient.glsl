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
    number line=segment(uv,vec2(.5,.76),vec2(.5,.27));
    for(int i=0;i<3;i++) {
        number y=.40+float(i)*.11;
        line=min(line,segment(uv,vec2(.5,y+.08),vec2(.31,y)));
        line=min(line,segment(uv,vec2(.5,y+.08),vec2(.69,y)));
    }
    // Angular stone channels: a white-hot core with a soft amber wake.
    line=min(line,segment(uv,vec2(.31,.38),vec2(.31,.65)));
    line=min(line,segment(uv,vec2(.69,.38),vec2(.69,.65)));
    number carved=exp(-line*180.0);
    number halo=exp(-line*38.0);
    number wake=exp(-pow(uv.y-(.80-fract(u_time*u_speed*.60)*.60),2.0)*65.0);
    number etching=sin(uv.x*340.0+sin(uv.y*19.0)*8.0)*.018;
    vec3 rgb=mix(base.rgb,base.rgb*vec3(.90,1.03,.90),min(.26,u_intensity*.18));
    rgb+=base.rgb*etching*u_intensity;
    number power=.36+wake*.65+u_scorePulse*.35+u_hoverAmount*.12;
    rgb+=vec3(1.0,.57,.15)*(carved*.65+halo*.20)*power*u_intensity;
    rgb+=vec3(1.0,.94,.69)*carved*wake*.55*u_intensity;
    return vec4(clamp(rgb,0.0,1.0),base.a);
}
