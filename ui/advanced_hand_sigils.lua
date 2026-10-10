local S={}
function S.draw(g,a,p,alpha,impact)
    local id=a.profile.id;local x,y=a.cx,impact and 270 or 350
    local expansion=1-(1-p)^3
    local r=impact and (30+expansion*(a.profile.mythic and 108 or 84)) or 38+18*p
    local scale=r/56
    g.push("all");g.translate(x,y)
    if impact then
        local image=require("render.lighting").radial
        if image then
            g.setColor(a.color[1],a.color[2],a.color[3],alpha*.23)
            g.draw(image,-r,-r*.65,0,r/64,r*.65/64)
        end
        g.scale(scale,scale);r=56
        g.setBlendMode("alpha")
    end
    g.setLineWidth(impact and (3.2*(1-p)+.7)/scale or 1.6)
    g.setColor(a.color[1],a.color[2],a.color[3],alpha)
    local function radial(n,offset)
        for i=1,n do local t=i*math.pi*2/n+(offset or 0);g.line(math.cos(t)*r*.35,math.sin(t)*r*.2,math.cos(t)*r,math.sin(t)*r*.55) end
    end
    if id=="tesla_369" then
        for i=1,3 do local t=i*math.pi*2/3;local bx,by=math.cos(t)*r,math.sin(t)*r*.65
            local snap=impact and math.sin(math.floor(p*18)*2.3+i)*3*(1-p) or 0
            g.circle("line",bx,by,6);g.line(0,0,bx*.28-4-snap,by*.32,bx*.48+5+snap,by*.51,bx*.72-3,by*.74,bx,by) end
    elseif id=="jackpot_777" then
        for i=1,3 do local bx=(i-2)*31;local drop=impact and p*p*24*(i-2) or 0
            g.rectangle("line",bx-10,-18+drop,20,36,3);g.line(bx-5,-7+drop,bx+5,-7+drop,bx-2,7+drop) end
    elseif id=="fibonacci" then
        local lastX,lastY
        g.rotate(impact and -p*.7 or p*.2)
        for i=0,42 do local t=i*.22;local rr=3*math.exp(t*.29);local bx,by=math.cos(t)*rr,math.sin(t)*rr*.55
            if lastX then g.line(lastX,lastY,bx,by) end;lastX,lastY=bx,by end
    elseif id=="prime" then
        for i,v in ipairs({2,3,5,7,11}) do local t=i*math.pi*2/5+(impact and p*.3 or .2);g.circle("line",math.cos(t)*r,math.sin(t)*r*.6,3+v*.45) end
    elseif id=="odd_star" then radial(9,p*.25);g.ellipse("line",0,0,r*.5,r*.25)
    elseif id=="even_frost" then radial(10,.15);for i=1,5 do local t=i*math.pi*2/5;local bx,by=math.cos(t)*r,math.sin(t)*r*.55
            g.line(bx*.5,by*.5,bx,by,bx*.73+math.sin(t)*9,by*.73-math.cos(t)*9) end
    elseif id=="crimson_tide" then
        for row=1,5 do local points=a.sigil;for i=0,16 do points[i*2+1]=-r+i*r/8;points[i*2+2]=math.sin(i*.4+p*4)*(impact and 10 or 7)+(row-3)*9 end;g.line(points) end
    elseif id=="obsidian_tide" then for i=1,5 do local bx=(i-3)*21;local rise=impact and -p*(6+i*3) or 0
        g.setColor(.13,.14,.22,alpha*.85);g.polygon("fill",bx-8,-20+rise,bx+8,-20+rise,bx+8,12+rise,bx,23+rise,bx-8,12+rise)
        g.setColor(a.color[1],a.color[2],a.color[3],alpha);g.polygon("line",bx-8,-20+rise,bx+8,-20+rise,bx+8,12+rise,bx,23+rise,bx-8,12+rise) end
    elseif id=="eclipse_duality" then g.rotate(p*(impact and -.45 or .3));g.circle("line",-16,0,28);g.arc("line","open",16,0,28,-1.3,1.3);g.arc("line","open",16,0,28,1.8,4.5)
    elseif id=="four_kingdom_prism" then
        g.polygon("line",0,-25,25,0,0,25,-25,0)
        for i,col in ipairs({{1,.3,.3},{1,.7,.25},{.3,.9,.55},{.45,.65,1}}) do g.setColor(col[1],col[2],col[3],alpha);local t=i*math.pi/2;g.line(0,0,math.cos(t)*r,math.sin(t)*r*.65) end
    elseif id=="four_kingdom_expedition" then radial(4,.785);g.ellipse("line",0,0,r,r*.55);g.polygon("line",0,-25,8,0,0,25,-8,0)
    elseif id=="destiny_crown" then local points=a.sigil;points[1],points[2]=-r,15
        for i=1,5 do local j=3+(i-1)*4;points[j]=-r+(i-1)*r/2;points[j+1]=-12-(i==3 and 17 or i%2*10);points[j+2]=-r+(i-.5)*r/2;points[j+3]=8 end
        g.line(points);g.line(-r,20,r,20)
        if impact then for i=1,5 do local bx=(i-3)*23;g.line(bx,-28,bx,-43-16*(1-p)) end end
    elseif id=="continental_gate" then for i=1,4 do local bx=(i-2.5)*25+(impact and (i<3 and -1 or 1)*p*16 or 0);g.rectangle("line",bx-6,-22,12,42) end;g.arc("line","open",0,-10,r*.8,math.pi,2*math.pi)
    elseif id=="answer_42" then radial(4,.3);for i=1,2 do g.ellipse("line",0,0,r*i/2,r*i/3) end
    elseif id=="sealed_gate" then g.scale(1+(impact and p*.35 or 0),1);g.rectangle("line",-r,-30,r*2,60);for i=1,3 do g.circle("line",(i-2)*27,-17,6) end;for i=1,2 do g.circle("line",(i-1.5)*27,17,9) end
    elseif id=="seven_stars" then local points=a.sigil;for i=1,7 do local t=i*2.399+(impact and p*.3 or 0);local bx,by=math.cos(t)*r,math.sin(t)*r*.6;g.circle("fill",bx,by,impact and 3.5 or 2.5);points[i*2-1]=bx;points[i*2]=by end;g.line(points)
    elseif id=="five_ley_lines" then radial(5,.2);g.ellipse("line",0,0,r,r*.6);for i=1,5 do local t=i*math.pi*2/5+.2;g.rectangle("line",math.cos(t)*r-4,math.sin(t)*r*.6-6,8,12) end
    elseif id=="endless_cycle" then local points=a.sigil;for i=0,48 do local t=i*math.pi/24+p*.6;points[i*2+1]=math.cos(t)*r;points[i*2+2]=math.sin(t*2)*r*.35 end;g.line(points) end
    g.pop()
end
return S
