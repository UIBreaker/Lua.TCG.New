// Local weapon surfaces and impact silhouettes. Never bound to the UI canvas.
extern number kind;
extern number burst;
extern number clock;
extern number power;
extern number bodyPass;
extern vec3 tint;
extern vec3 accent;
const float PI=3.14159265;
float capsule(vec2 p,vec2 a,vec2 b,float r){vec2 q=p-a,v=b-a;return length(q-v*clamp(dot(q,v)/dot(v,v),0.,1.))-r;}
float box(vec2 p,vec2 b){vec2 d=abs(p)-b;return length(max(d,0.))+min(max(d.x,d.y),0.);}
float ring(vec2 p,float r,float w){return abs(length(p)-r)-w;}
vec2 rotate(vec2 p,float a){return mat2(cos(a),-sin(a),sin(a),cos(a))*p;}
float star(vec2 p,float n,float r,float depth){
    float sector=2.*PI/n;float a=mod(atan(p.y,p.x)+2.*PI,sector);a=min(a,sector-a);
    vec2 v=vec2(cos(PI/n),sin(PI/n))*r*(1.-depth)-vec2(r,0.);
    float edge=r*v.y/(cos(a)*v.y-sin(a)*v.x);
    return length(p)-edge;
}
float infinity(vec2 p){p.x*=.84;float f=dot(p,p);return abs(f*f-.32*(p.x*p.x-p.y*p.y))/(.1+2.*f)-.025;}
float weapon(vec2 p){
    float d=1.;
    if(kind<1.5){ // Forged sword: curved taper, broad fuller, guard, grip and pommel.
        float width=.07+.045*sin(clamp((p.x+.25)/.95,0.,1.)*PI);
        d=max(abs(p.y)-width*(1.-smoothstep(.42,.82,p.x)),max(-p.x-.32,p.x-.82));
        d=min(d,capsule(p,vec2(-.32,-.22),vec2(-.27,.22),.035));
        d=min(d,box(p-vec2(-.51,0.),vec2(.18,.038)));
        d=min(d,length((p-vec2(-.73,0.))*vec2(1.,.8))-.07);
    }else if(kind<2.5){ // Crescent is a curved mass, not a triangle.
        d=max(length(p)-.67,-(length(p-vec2(-.26,.08))-.61));
    }else if(kind<3.5){
        d=capsule(p,vec2(-.83,0.),vec2(.43,0.),.024);
        d=min(d,max(abs(p.y)-.14*(1.-abs(p.x-.48)/.36),abs(p.x-.48)-.36));
        d=min(d,capsule(p,vec2(.14,-.12),vec2(.14,.12),.018));
    }else if(kind<4.5){
        d=capsule(p,vec2(-.73,0.),vec2(.65,0.),.022);
        d=min(d,capsule(p,vec2(.35,-.18),vec2(.74,0.),.035));
        d=min(d,capsule(p,vec2(.35,.18),vec2(.74,0.),.035));
        d=min(d,max(abs(p.y)-.1,abs(p.x+.53)-.12));
    }else if(kind<5.5){
        float a=atan(p.y,p.x);d=length(p)-(.52+.035*sin(a*5.)+.055*sin(a*7.+1.));
    }else if(kind<6.5){
        d=max(abs(p.y)-.21*(1.-.6*abs(p.x)),abs(p.x)-.72);
        d=max(d,(abs(p.x)+abs(p.y)*.65)-.76);
    }else if(kind<7.5){
        d=abs(p.y-.075*sin(p.x*17.+floor(clock*12.))-.04*sin(p.x*37.))-.018;d=max(d,abs(p.x)-.84);
    }else if(kind<8.5){d=length(p*vec2(1.,1.10))-.57;
    }else if(kind<9.5){d=star(rotate(p,PI/2.),5.,.72,.36);
    }else if(kind<10.5){d=capsule(p,vec2(-.82,0.),vec2(.82,0.),.035);
    }else if(kind<11.5){d=star(p,4.,.75,.55);
    }else if(kind<12.5){d=length(p)-.52;
    }else if(kind<13.5){
        d=abs(p.y-.25*sin(p.x*3.+clock*2.))-.08*(1.-p.x*p.x);d=max(d,abs(p.x)-.8);
    }else if(kind<14.5){ // Crown: substantial curved band and five sculpted prongs.
        d=max(ring(p-vec2(0.,-.10),.48,.06),-p.y-.08);
        for(int i=0;i<5;i++){float x=float(i-2)*.19;float h=.48-abs(x)*.52;
            d=min(d,capsule(p,vec2(x,.23),vec2(x,-h),.034));
            d=min(d,length(p-vec2(x,-h))-.065);}
    }else if(kind<15.5){d=infinity(p);
    }else if(kind<16.5){d=star(rotate(p,PI/2.),7.,.71,.31);
    }else if(kind<17.5){d=ring(p,.57,.035);d=min(d,ring(p,.46,.012));
        float a=atan(p.y,p.x);d=min(d,max(abs(sin(a*8.))*.12-.013,abs(length(p)-.52)-.04));
    }else if(kind<18.5){d=min(ring(p,.58,.016),star(rotate(p,clock),4.,.56,.86));
    }else if(kind<19.5){d=min(box(p-vec2(-.38,0.),vec2(.035,.65)),box(p-vec2(.38,0.),vec2(.035,.65)));}
    else {d=star(rotate(p,.28),5.,.65,.22);}
    return d;
}
float explosion(vec2 p){
    float t=clamp(clock/.42,0.,1.);float r=.14+.54*(1.-pow(1.-t,3.));
    float a=atan(p.y,p.x),l=length(p),w=.014+.028*(1.-t),d=1.;
    if(kind<1.5){vec2 q=rotate(p,.65);d=min(abs(length(q*vec2(1.,3.8))-r)-w,capsule(q,vec2(-r,0.),vec2(r,0.),w*.8));}
    else if(kind<2.5){d=min(capsule(p,vec2(-r,-r),vec2(r,r),w),capsule(p,vec2(-r,r),vec2(r,-r),w));}
    else if(kind<3.5){d=max(abs(l-r)-w,-abs(p.x)+.15);d=min(d,abs(p.y-.23*sin(p.x*5.))-.01);d=max(d,abs(p.x)-r);}
    else if(kind<4.5){d=abs(max(abs(p.x)*.866+p.y*.5,-p.y)-r*.65)-w;}
    else if(kind<5.5){d=max(abs(sin((a+PI*.5)*7.))*.1-w,abs(l-r*.8)-r*.32);d=max(d,p.y-.12);}
    else if(kind<6.5){d=abs(l-r*(.7+.20*sin(a*3.+t*8.)))-w;}
    else if(kind<7.5){
        float flame=length(p*vec2(1.,1.2))-r*(.55+.10*sin(a*7.+t*8.)+.05*sin(a*13.));
        d=min(flame,abs(length(p*vec2(1.,3.8))-r*1.25)-w*.7);}
    else if(kind<8.5){d=min(star(p,4.,r,.7),abs(length(p*vec2(1.,2.5))-r)-w);}
    else if(kind<9.5){d=min(capsule(p,vec2(0.,-r*1.4),vec2(0.,r),w*1.9),abs(length(p*vec2(1.,2.5))-r)-w);}
    else if(kind<10.5){d=abs(l-r*(.82+.09*sin(a*13.+t*9.)+.07*sin(a*29.)))-w;}
    else if(kind<11.5){d=abs(star(p,5.,r,.40))-w;}
    else if(kind<12.5){d=abs(l-r*(.7+.28*cos(a*5.)))-w*1.4;}
    else if(kind<13.5){d=abs(star(rotate(p,PI/2.),5.,r,.44))-w;}
    else if(kind<14.5){d=abs(l-r*(.92+.06*sin(a*27.-t*4.)))-w*1.8;}
    else if(kind<15.5){d=star(rotate(p,t*.3),6.,r,.55);d=max(d,-l+r*.3);}
    else if(kind<16.5){d=abs(length(p*vec2(1.,1.5)) -r*(1.+.08*sin(a*7.-t*6.)))-w*2.;}
    else if(kind<17.5){d=star(rotate(p,.2),7.,r,.65);d=max(d,-l+r*.42);}
    else if(kind<18.5){d=abs(l-r)-w*2.;}
    else if(kind<19.5){d=abs(star(rotate(p,.4),4.,r,.48))-w;}
    else if(kind<20.5){d=abs(l-r*(.75+.22*sin(a*4.-t*9.)))-w;}
    else if(kind<21.5){d=min(abs(length(p*vec2(1.,2.2))-r)-w, max(abs(sin(a*5.))*.1-w,abs(l-r*.7)-r*.25));}
    else if(kind<22.5){d=min(abs(length(rotate(p,.4)*vec2(1.,1.8))-r)-w,abs(length(rotate(p,-.6)*vec2(1.,1.8))-r*.8)-w*.7);}
    else if(kind<23.5){d=abs(star(rotate(p,PI/4.),8.,r,.7))-w*.6;}
    else if(kind<24.5){vec2 q=vec2(abs(p.x),p.y);d=1.;
        for(int i=0;i<5;i++){float f=float(i)/4.;d=min(d,capsule(q,vec2(r*.08,r*.18),vec2(r*(1.05-f*.40),r*(-.68+f*.85)),w*(1.25-f*.4)));}}
    else if(kind<25.5){d=abs(star(rotate(p,PI/2.),7.,r,.44))-w;}
    else if(kind<26.5){d=max(abs(sin(a*2.5+t*1.4))*.11-w,abs(l-r*.65)-r*.4);}
    else {d=abs(l-r*(.7+.2*sin(a*2.-t*12.)))-w;d=min(d,abs(l-r*.48)-w*.5);}
    return d;
}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen){
    vec2 p=(uv-.5)*2.;float d=burst>.5?explosion(p):weapon(p);
    float edge=exp(-abs(d)*90.);float halo=exp(-max(d,0.)*15.)*.19;
    float inside=1.-smoothstep(-.008,.01,d);
    float lighting=.30+.38*clamp(.6-p.y*.9-p.x*.24,0.,1.);
    vec3 hue=mix(tint,accent,.5+.5*sin(atan(p.y,p.x)*2.+clock*3.));
    if(bodyPass>.5){
        vec3 base=kind>19.5?vec3(.018,.011,.035):vec3(.13,.045,.016);
        return vec4((base*(.55+lighting)+vec3(.055)*edge)*color.rgb,inside*color.a);
    }
    vec3 rgb=tint*halo+mix(hue*lighting,vec3(1.,.97,.89),edge*.73)*inside;
    float alpha=max(inside,halo);
    if(burst>.5){
        float life=pow(max(0.,1.-clock/.42),1.5);float core=exp(-dot(p,p)/( .004+.024*min(clock/.045,1.)))*exp(-clock*16.);
        float turbulence=.65+.35*sin(p.x*49.+sin(p.y*37.)+clock*32.)*sin(p.y*41.-clock*23.);
        float plume=exp(-abs(d)*23.)*turbulence;
        float jets=pow(max(0.,cos(atan(p.y,p.x)*(3.+mod(kind,7.))+sin(length(p)*12.-clock*18.))),12.);
        jets*=exp(-length(p)*4.)*(1.-exp(-clock*90.))*exp(-clock*9.);
        rgb=(hue*(halo*1.7+plume*.44+jets*1.3)+mix(hue,vec3(1.,.98,.91),edge*.72)*inside+core*vec3(1.,.98,.90)*2.)*life;
        alpha=max(alpha*life,core);
        if(kind>17.5&&kind<18.5){rgb*=smoothstep(.14,.28,length(p));alpha*=smoothstep(.12,.22,length(p));}
    }else{
        float spine=exp(-abs(p.y)*100.)*(1.-smoothstep(.62,.85,abs(p.x)));
        if(kind<4.5|| (kind>9.5&&kind<11.5))rgb+=vec3(.95,.98,1.)*spine*inside*.68;
        if(kind>4.5&&kind<5.5){float cracks=pow(max(0.,sin(p.x*21.+sin(p.y*14.))*sin(p.y*19.+p.x*7.)),10.);rgb=rgb*.48+hue*cracks*1.8*inside;}
        if(kind>7.5&&kind<8.5){float rim=exp(-abs(length(p*vec2(1.,1.1))-.45)*100.);rgb+=vec3(1.,.87,.4)*rim*.65;rgb+=vec3(.8)*max(0.,1.-length(p-vec2(-.2,-.25))*5.)*inside;}
        if(kind>11.5&&kind<12.5){float plasma=pow(max(0.,sin(length(p)*25.-clock*9.+sin(atan(p.y,p.x)*3.))),8.);rgb+=hue*plasma*inside*.5;rgb+=vec3(.9)*exp(-dot(p+vec2(.13,.15),p+vec2(.13,.15))*60.);}
        if(kind>19.5){float cracks=pow(max(0.,cos(p.x*23.+sin(p.y*18.))),22.);rgb=hue*(.06+cracks*1.3)*inside+hue*halo*.7+vec3(.25,.19,.34)*edge*.3;}
        rgb*=.9+power*.22;
    }
    float border=1.-smoothstep(.85,1.,max(abs(p.x),abs(p.y)));
    // RGB is emitted energy, already faded by life; additive premultiplied blending
    // preserves the soft halo without squaring its falloff a second time.
    return vec4(rgb*color.rgb*color.a*border,alpha*color.a*border);
}
