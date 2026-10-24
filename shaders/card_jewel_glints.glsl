extern number uTime;
extern number uMoving;
extern number uTier;
extern number uAscended;
extern number uLow;
extern number uRank;
extern number uMaterial;

number hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
number band(number phase,number width) {
    return pow(max(0.0,1.0-abs(fract(phase)-0.5)*width),3.0);
}

vec4 effect(vec4 color,Image image,vec2 uv,vec2 screen) {
    vec4 p=Texel(image,uv);
    if(p.a<0.003) return vec4(0.0);
    vec3 surface=p.rgb/max(p.a,0.003);
    number luminance=dot(surface,vec3(0.2126,0.7152,0.0722));
    number saturation=max(surface.r,max(surface.g,surface.b))-min(surface.r,min(surface.g,surface.b));
    number gemstone=smoothstep(0.10,0.38,saturation);
    if(uMaterial>0.5) {
        // Polish the existing relief and gemstone facets without changing its alpha or silhouette.
        number relief=1.06+uRank*0.009+step(10.5,uRank)*0.035;
        vec3 enamel=mix(vec3(luminance),surface,1.04+gemstone*0.12);
        vec3 metal=(enamel-0.20)*relief+0.20;
        metal+=surface*smoothstep(0.48,0.92,luminance)*(0.035+uRank*0.003);
        if(uRank>10.5) metal+=vec3(0.045,0.038,0.022)*smoothstep(0.20,0.72,luminance);
        return vec4(clamp(metal,0.0,1.0)*p.a,p.a)*color;
    }
    number polished=smoothstep(0.16,0.68,luminance);
    number travel=fract(uv.y*0.61+uv.x*0.39-uTime*(0.075+uTier*0.035));
    number sweep=pow(max(0.0,1.0-abs(travel-0.5)*17.0),3.0);
    number counter=fract(uv.y*0.67-uv.x*0.33+uTime*0.063);
    number second=pow(max(0.0,1.0-abs(counter-0.5)*25.0),3.0)*smoothstep(0.45,1.0,uTier);
    vec2 cells=vec2(48.0,72.0);
    vec2 cell=floor(uv*cells);
    vec2 local=fract(uv*cells)-0.5;
    number seed=hash(cell);
    number selected=step(0.985-uTier*0.055+uLow*0.035,seed);
    number beat=pow(max(0.0,sin(uTime*(1.5+seed)+seed*31.0)),18.0);
    number diamond=pow(max(0.0,1.0-abs(local.x)*2.0-abs(local.y)*2.0),4.0);
    number cross=exp(-abs(local.x)*42.0)*exp(-abs(local.y)*5.0)
                +exp(-abs(local.y)*42.0)*exp(-abs(local.x)*5.0);
    number glint=selected*beat*(diamond+cross*(0.35+uTier))*polished;
    number motif=0.0;
    number gemBeat=0.0;
    number crown=exp(-length((uv-vec2(0.5,0.065))*vec2(4.5,5.0)));
    if(uRank<2.5) {
        // Verdigris leaves: one slow rising reflection along the engraved rails.
        motif=band(uv.y+uTime*0.10,12.0)*0.65;
        gemBeat=gemstone*(0.16+0.14*sin(uTime*1.8+uv.y*5.0));
    } else if(uRank<3.5) {
        // Sapphire shields: alternating cold flashes in the two side settings.
        motif=band(uv.y-uTime*0.18,20.0)*0.9;
        gemBeat=gemstone*pow(max(0.0,sin(uTime*2.1+step(0.5,uv.x)*3.14159)),4.0)*0.75;
    } else if(uRank<4.5) {
        // Amethyst crescents: a gentle lunar breathing cycle rather than a fast sweep.
        motif=(0.5+0.5*sin(uTime*1.35+uv.y*5.0))*0.22;
        gemBeat=gemstone*pow(0.5+0.5*sin(uTime*1.35),3.0)*0.85;
    } else if(uRank<5.5) {
        // Laurel crown: reflections fan out from the crown into the gold leaves.
        motif=band(abs(uv.x-0.5)*1.8+uv.y*0.4-uTime*0.18,15.0)*1.15;
        gemBeat=gemstone*(0.25+band(uTime*0.23+uv.y,8.0))*0.5;
    } else if(uRank<6.5) {
        // Ruby feathers: ascending tongues follow the existing sculpted vanes.
        motif=band(uv.y*1.7+abs(uv.x-0.5)*0.7+uTime*0.30,12.0)*1.2;
        gemBeat=gemstone*pow(max(0.0,sin(uTime*2.7-uv.y*7.0)),4.0)*0.95;
    } else if(uRank<7.5) {
        // Ice ribs: narrow opposing refractions slide down alternate platinum rails.
        motif=band(uv.y*2.4-uTime*0.28*sign(uv.x-0.5),24.0)*1.6;
        gemBeat=gemstone*band(uv.y*1.3-uTime*0.22,10.0)*1.1;
    } else if(uRank<8.5) {
        // Astronomical mounts: orbiting highlights trace the real metal rings.
        number orbit=atan((uv.y-0.08)*1.5,uv.x-0.5)/6.28318;
        motif=band(orbit-uTime*0.16,12.0)*(0.45+crown*1.5);
        gemBeat=gemstone*pow(max(0.0,sin(uTime*2.0+uv.y*18.0)),10.0)*1.25;
    } else if(uRank<9.5) {
        // Infinity braid: paired reflections interleave in opposite directions.
        motif=(band(uv.y+sin(uv.x*12.566)*0.13-uTime*0.20,15.0)
            +band(uv.y-sin(uv.x*12.566)*0.13+uTime*0.20,15.0))*0.95;
        gemBeat=gemstone*(0.25+pow(max(0.0,sin(uTime*1.7)),4.0))*0.9;
    } else if(uRank<10.5) {
        // Supreme wings: broad, measured white-gold reflections along the feathers.
        motif=band(abs(uv.x-0.5)*1.6+uv.y*0.8-uTime*0.24,14.0)*1.25;
        gemBeat=gemstone*0.35+crown*pow(max(0.0,sin(uTime*1.8)),6.0)*0.9;
    } else {
        // Level ten keeps its existing double wings and opal crown; three waves awaken them.
        number distance=length((uv-vec2(0.5,0.065))*vec2(1.1,0.72));
        number waves=band(distance*2.6-uTime*0.42,10.0)
            +band(distance*2.6-uTime*0.42+0.333,15.0)*0.75
            +band(distance*2.6-uTime*0.42+0.666,15.0)*0.75;
        number coronation=pow(0.5+0.5*sin(uTime*2.2),6.0);
        number rays=pow(max(0.0,cos(atan((uv.y-0.065)*1.5,uv.x-0.5)*10.0-uTime*0.45)),8.0);
        motif=0.28+waves*2.0+crown*(0.45+coronation*2.4+rays*0.85);
        gemBeat=gemstone*(0.5+coronation*1.2)+crown*coronation;
    }
    number strength=0.07+uTier*0.27+uAscended*0.14;
    number light=uMoving*polished*((sweep+second*0.35)*strength+motif*(0.13+uTier*0.21));
    number sparkle=uMoving*(glint*(0.35+uTier*1.25+uAscended*1.1)+gemBeat*(0.12+uTier*0.23));
    // Reflections stay anchored to the original frame pixels, even during the apex burst.
    vec3 fire=mix(vec3(1.0,0.94,0.82),clamp(surface*1.4,0.0,1.0),gemstone*0.55);
    if(uAscended>0.5) fire=mix(fire,vec3(0.88+0.12*sin(uTime*1.3+uv.y*8.0),0.94,1.0),gemstone*0.18);
    vec3 reflection=p.rgb*light+fire*p.a*sparkle;
    // A soft highlight ceiling preserves the engraved relief at the peak of a burst.
    vec3 ceiling=max(vec3(0.015)*p.a,vec3(p.a)-p.rgb)*0.75;
    reflection=ceiling*(vec3(1.0)-exp(-reflection/max(ceiling,vec3(0.0001))));
    return vec4(reflection*color.rgb,p.a*color.a*clamp(light+sparkle,0.0,1.0));
}
