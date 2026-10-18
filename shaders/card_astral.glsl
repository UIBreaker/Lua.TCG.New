extern number u_time;
extern number u_intensity;
extern number u_speed;
extern number u_scorePulse;
extern vec2 u_tilt;

number hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
number segment(vec2 p,vec2 a,vec2 b) {
    vec2 v=b-a;
    return length(p-a-v*clamp(dot(p-a,v)/dot(v,v),0.0,1.0));
}
number beacon(vec2 p) {
    return exp(-dot(p,p)*4800.0)
        +exp(-abs(p.x)*260.0-abs(p.y)*38.0)*.65
        +exp(-abs(p.y)*260.0-abs(p.x)*38.0)*.65;
}
vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen_coords) {
    vec4 base=Texel(texture,uv)*color;
    if(base.a<=.003) return vec4(0.0);
    number t=u_time*u_speed;
    vec2 grid=uv*vec2(8.0,12.0);
    vec2 cell=floor(grid);
    number seed=hash(cell);
    vec2 star=fract(grid)-(vec2(hash(cell+7.1),hash(cell+19.3))*.56+.22);
    number twinkle=.4+.6*pow(.5+.5*sin(t*3.0+seed*30.0),3.0);
    number cross=exp(-abs(star.x)*65.0-abs(star.y)*8.0)+exp(-abs(star.y)*65.0-abs(star.x)*8.0);
    cross+=exp(-dot(star,star)*65.0)*.23;
    number stars=step(.88,seed)*cross*twinkle;
    vec2 p=(uv-vec2(.5))*vec2(1.0,1.5);
    number orbits=0.0;
    number comets=0.0;
    for(int i=0;i<1;i++) {
        number angle=float(i)*1.0472+t*.17+u_tilt.x*.12;
        vec2 q=mat2(cos(angle),-sin(angle),sin(angle),cos(angle))*p;
        number ellipse=length(q*vec2(1.0,2.4));
        orbits+=exp(-pow(ellipse-.36,2.0)*3500.0)*.36;
        orbits+=exp(-pow(ellipse-.36,2.0)*260.0)*.045;
        number phase=t*(.8+float(i)*.15)+float(i)*1.7;
        vec2 head=vec2(cos(phase)*.36,sin(phase)*.15);
        number d=length(q-head);
        comets+=exp(-d*d*2800.0)+exp(-d*d*180.0)*.16;
        // Three tapering samples make a short comet tail on each orbit.
        for(int j=1;j<=3;j++) {
            number lag=float(j);
            vec2 tail=vec2(cos(phase-lag*.12)*.36,sin(phase-lag*.12)*.15);
            number tailD=length(q-tail);
            comets+=exp(-tailD*tailD*(3000.0+lag*1000.0))*(.36-lag*.08);
        }
    }
    vec3 rgb=base.rgb+vec3(.58,.83,1.0)*stars*1.10*u_intensity;
    rgb+=vec3(.95,.84,.56)*orbits*u_intensity*(.7+u_scorePulse);
    rgb+=vec3(.80,.93,1.0)*comets*u_intensity;
    number path=1.0, beacons=0.0;
    for(int i=0;i<5;i++) {
        number angle=float(i)*2.513274+t*.06;
        vec2 a=vec2(sin(angle),-cos(angle))*.30;
        vec2 b=vec2(sin(angle+2.513274),-cos(angle+2.513274))*.30;
        path=min(path,segment(p,a,b));
        beacons+=beacon(p-a);
    }
    number constellation=exp(-path*180.0)*.60+exp(-path*45.0)*.075;
    rgb+=vec3(.55,.78,1.0)*constellation*u_intensity;
    rgb+=vec3(.82,.94,1.0)*beacons*(.72+.12*sin(t*1.7))*u_intensity;
    return vec4(clamp(rgb,0.0,1.0),base.a);
}
