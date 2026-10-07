extern number u_time;
extern number u_intensity;
extern number u_speed;
extern number u_scorePulse;
extern vec2 u_tilt;

number hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen_coords) {
    vec4 base=Texel(texture,uv)*color;
    if(base.a<=.003) return vec4(0.0);
    number t=u_time*u_speed;
    vec2 grid=uv*vec2(8.0,12.0);
    vec2 cell=floor(grid);
    vec2 star=fract(grid)-vec2(.5);
    number seed=hash(cell);
    number twinkle=.4+.6*pow(.5+.5*sin(t*3.0+seed*30.0),3.0);
    number cross=exp(-abs(star.x)*65.0-abs(star.y)*8.0)+exp(-abs(star.y)*65.0-abs(star.x)*8.0);
    cross+=exp(-dot(star,star)*65.0)*.23;
    number stars=step(.88,seed)*cross*twinkle;
    vec2 p=(uv-vec2(.5))*vec2(1.0,1.5);
    number orbits=0.0;
    number comets=0.0;
    for(int i=0;i<4;i++) {
        number angle=float(i)*.7854+t*.23+u_tilt.x*.12;
        vec2 q=mat2(cos(angle),-sin(angle),sin(angle),cos(angle))*p;
        number ellipse=length(q*vec2(1.0,2.4));
        orbits+=exp(-pow(ellipse-.36,2.0)*3500.0)*.36;
        orbits+=exp(-pow(ellipse-.36,2.0)*260.0)*.045;
        number phase=t*(.8+float(i)*.15)+float(i)*1.7;
        vec2 head=vec2(cos(phase)*.36,sin(phase)*.15);
        number d=length(q-head);
        comets+=exp(-d*d*2800.0)+exp(-d*d*180.0)*.16;
    }
    vec3 rgb=base.rgb+vec3(.58,.83,1.0)*stars*1.10*u_intensity;
    rgb+=vec3(.95,.84,.56)*orbits*u_intensity*(.7+u_scorePulse);
    rgb+=vec3(.80,.93,1.0)*comets*u_intensity;
    return vec4(clamp(rgb,0.0,1.0),base.a);
}
