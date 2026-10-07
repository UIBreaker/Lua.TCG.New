extern number u_time;
extern number u_intensity;
extern number u_speed;
extern number u_hoverAmount;
extern number u_scorePulse;
extern vec2 u_tilt;

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen_coords) {
    vec4 original=Texel(texture,uv)*color;
    if(original.a<=.003) return vec4(0.0);
    vec2 p=(uv-vec2(.5))*vec2(1.0,1.5);
    number r=length(p);
    number a=atan(p.y,p.x);
    number force=exp(-r*5.0)*u_intensity*(.025+u_hoverAmount*.02+u_scorePulse*.025);
    vec2 twist=vec2(-p.y,p.x)*sin(u_time*u_speed*1.5-r*13.0)*force;
    vec2 warped=clamp(uv+twist+p*force,vec2(.001),vec2(.999));
    vec3 rgb=Texel(texture,warped).rgb*color.rgb;
    number ring=exp(-pow(r-.24-sin(a*3.0+u_time*u_speed)*.018,2.0)*1300.0);
    number spiral=pow(max(0.0,cos(a*2.0+r*19.0-u_time*u_speed*2.0)),16.0)*exp(-pow(r-.26,2.0)*45.0);
    number core=1.0-smoothstep(.04,.20,r);
    number halo=exp(-pow(r-.24,2.0)*130.0);
    number filaments=pow(max(0.0,sin(a*5.0-r*32.0+u_time*u_speed*2.0)),22.0)*exp(-pow(r-.29,2.0)*90.0);
    rgb*=1.0-core*min(.65,u_intensity*.38);
    rgb+=vec3(.54,.10,.92)*(ring*.40+spiral*.25+halo*.12+filaments*.22)*u_intensity;
    rgb+=vec3(.92,.64,1.0)*ring*.28*u_intensity;
    return vec4(clamp(rgb,0.0,1.0),original.a);
}
