extern number u_time;
extern number u_intensity;
extern number u_speed;
extern vec2 u_tilt;
extern number u_hoverAmount;
extern number u_scorePulse;
extern number u_selectPulse;

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen_coords) {
    vec4 base=Texel(texture,uv)*color;
    if(base.a<=0.003) return vec4(0.0);
    vec2 p=(uv-vec2(0.5,0.55))*vec2(1.0,1.5);
    number r=length(p);
    number t=u_time*u_speed;
    number emboss=pow(max(0.0,sin(atan(p.y,p.x)*8.0)),12.0);
    number seal=exp(-pow(r-0.29,2.0)*1800.0)*(0.5+emboss);
    number halo=exp(-pow(r-.29,2.0)*140.0);
    number inner=exp(-pow(r-.235,2.0)*4200.0);
    number rays=pow(max(0.0,cos(atan(p.y,p.x)*12.0-t*.7)),24.0)*exp(-pow(r-.32,2.0)*120.0);
    number ring=exp(-pow(r-(0.12+fract(t*0.3)*0.5),2.0)*900.0);
    number gild=pow(max(0.0,sin(uv.y*5.0-t*1.7+u_tilt.x)),8.0);
    number pulse=0.65+u_scorePulse*0.5+u_selectPulse*0.2;
    number luminance=dot(base.rgb,vec3(0.2126,0.7152,0.0722));
    vec3 gold=vec3(1.0,0.67,0.20);
    vec3 rgb=mix(base.rgb,vec3(luminance)*vec3(1.25,0.95,0.56),min(0.30,u_intensity*0.2));
    rgb+=gold*(seal*.62+halo*.10+ring*.24+gild*.20+rays*.16)*u_intensity*pulse;
    rgb+=vec3(1.0,.91,.64)*inner*.42*u_intensity*pulse;
    return vec4(clamp(rgb,0.0,1.0),base.a);
}
