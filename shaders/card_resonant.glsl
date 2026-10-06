extern number u_time;
extern number u_intensity;
extern number u_speed;
extern number u_hoverAmount;
extern number u_scorePulse;

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen_coords) {
    vec4 base=Texel(texture,uv)*color;
    if(base.a<=.003) return vec4(0.0);
    number t=u_time*u_speed;
    number envelope=sin(uv.x*3.14159);
    number wave1=.53+sin(uv.x*18.85-t*5.0)*.035*envelope;
    number wave2=.53-sin(uv.x*18.85+t*5.0)*.035*envelope;
    number waves=exp(-pow(uv.y-wave1,2.0)*19000.0)+exp(-pow(uv.y-wave2,2.0)*19000.0);
    number nodes=0.0;
    for(int i=0;i<3;i++) {
        vec2 p=(uv-vec2(.18+float(i)*.32,.53))*vec2(1.0,1.5);
        nodes+=exp(-dot(p,p)*1200.0)*(.5+.5*sin(t*5.0-float(i)*1.2));
    }
    number inbound=exp(-pow(abs(uv.x-.5)-(.46-fract(t*.5)*.46),2.0)*2200.0)*exp(-pow(uv.y-.53,2.0)*280.0);
    vec3 rgb=base.rgb+vec3(.3,.91,1.0)*(waves*.48+nodes*.65+inbound*.30)*u_intensity*(.65+u_hoverAmount*.25+u_scorePulse*.6);
    return vec4(clamp(rgb,0.0,1.0),base.a);
}
