extern vec2 screenCenter;
extern float clock;
extern float material;
extern float charge;
extern float pixelScale;

float grain(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
vec4 effect(vec4 tint,Image texture,vec2 uv,vec2 pixel) {
    vec2 q=(pixel-screenCenter)/max(.1,pixelScale);
    float ridge=.5+.5*sin(q.x*.12-q.y*.075+clock*5.0);
    float noise=grain(floor(q*.22));
    float shade=.58+.22*ridge;
    float edge=.0;
    if(material<1.5) { // compressed, warm physical aura
        shade=.46+.22*ridge;edge=pow(max(0.0,sin(q.y*.095-clock*7.0)),12.0)*.20;
    } else if(material<2.5) { // crystalline refraction and visible fracture veins
        float vein=abs(sin(q.x*.15+q.y*.12+sin(q.y*.08)*2.0));
        shade=.42+.25*ridge;edge=(1.0-smoothstep(.0,.075,vein))*.34;
    } else if(material<3.5) { // electric surface, animated without gameplay RNG
        shade=.72;edge=pow(noise,12.0)*.24;
    } else if(material<4.5) { // metallic glint moving across assembled surfaces
        shade=.38+.32*ridge;edge=pow(max(0.0,sin(q.x*.045+q.y*.025-clock*2.0)),24.0)*.32;
    } else if(material<5.5) { // controlled travelling filaments
        shade=.48+.22*ridge;edge=pow(max(0.0,sin(q.y*.10-clock*8.0)),10.0)*.22;
    } else if(material<6.5) { // corona/rift material, a dark body under a spectral edge
        shade=.24+.24*ridge;edge=pow(max(0.0,sin(length(q)*.09-clock*3.0)),14.0)*.26;
    } else if(material<7.5) { // flowing cloth/water, broad bands instead of crystal fracture
        float flow=sin(q.x*.065+sin(q.y*.09+clock*3.0)*1.5-clock*5.0);
        shade=.38+.28*(.5+.5*flow);edge=pow(max(0.0,flow),8.0)*.22;
    } else { // heavy obsidian: dark rough planes, hot fracture edges
        float crack=abs(sin(q.x*.16+q.y*.11+floor(q.y*.05)*1.7));
        shade=.16+.19*noise;edge=(1.0-smoothstep(.0,.06,crack))*.40;
    }
    vec3 body=tint.rgb*shade+mix(tint.rgb,vec3(1.0,.96,.83),.34)*edge*charge;
    return vec4(body,tint.a);
}
