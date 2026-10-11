extern vec2 screenCenter;
extern float clock;
extern float material;
extern float charge;
extern float pixelScale;
extern vec2 surfaceCenter;
extern vec2 surfaceRadius;
extern float surfaceVolume;

vec4 effect(vec4 tint,Image texture,vec2 uv,vec2 pixel) {
    vec2 q=(pixel-screenCenter)/max(.1,pixelScale);
    float ridge=.5+.5*sin(q.x*.065-q.y*.04+clock*2.2);
    // Continuous fine grain avoids crawling square blocks when the camera moves.
    float noise=.5+.25*sin(q.x*.73+q.y*.51)+.25*sin(q.x*1.13-q.y*.87);
    float shade=.58+.22*ridge;
    float edge=.0;
    if(material<1.5) { // compressed, warm physical aura
        shade=.38+.39*ridge;edge=pow(max(0.0,sin(q.y*.065-clock*3.0)),20.0)*.28;
    } else if(material<2.5) { // crystalline refraction and visible fracture veins
        float vein=abs(sin(q.x*.15+q.y*.12+sin(q.y*.08)*2.0));
        shade=.30+.43*ridge;edge=(1.0-smoothstep(.025,.12,vein))*.42;
    } else if(material<3.5) { // electric surface, animated without gameplay RNG
        shade=.55+.17*ridge;edge=pow(noise,9.0)*.36;
    } else if(material<4.5) { // metallic glint moving across assembled surfaces
        shade=.26+.46*ridge;edge=pow(max(0.0,sin(q.x*.045+q.y*.025-clock*1.4)),28.0)*.42;
    } else if(material<5.5) { // controlled travelling filaments
        shade=.34+.36*ridge;edge=pow(max(0.0,sin(q.y*.07-clock*4.0)),16.0)*.30;
    } else if(material<6.5) { // corona/rift material, a dark body under a spectral edge
        shade=.18+.27*ridge;edge=pow(max(0.0,sin(length(q)*.09-clock*2.0)),20.0)*.42;
    } else if(material<7.5) { // flowing cloth/water, broad bands instead of crystal fracture
        float flow=sin(q.x*.065+sin(q.y*.09+clock*3.0)*1.5-clock*5.0);
        shade=.26+.42*(.5+.5*flow);edge=pow(max(0.0,flow),12.0)*.30;
    } else { // heavy obsidian: dark rough planes, hot fracture edges
        float crack=abs(sin(q.x*.16+q.y*.11+floor(q.y*.05)*1.7));
        shade=.13+.17*ridge+.04*noise;edge=(1.0-smoothstep(.02,.09,crack))*.46;
    }
    // Broad surface light gives the filled silhouette volume without geometric outlines.
    float light=.5+.5*sin(q.x*.024-q.y*.018-clock*.85);
    float sheen=pow(light,10.0)*.30;
    vec3 body=tint.rgb*(shade+.22)+mix(tint.rgb,vec3(.94,.98,1.0),.65)*(edge+sheen)*charge;
    if(surfaceVolume>.5) {
        vec2 v=(pixel-surfaceCenter)/max(surfaceRadius,vec2(.1));
        float z=sqrt(max(0.0,1.0-dot(v,v)));
        float diffuse=clamp(.35+.65*z-.24*v.x-.18*v.y,.22,1.25);
        float specular=pow(max(0.0,z-.30*v.x-.25*v.y),18.0)*.35;
        body=body*diffuse+vec3(.82,.94,1.0)*specular*charge;
    }
    return vec4(body,tint.a);
}
