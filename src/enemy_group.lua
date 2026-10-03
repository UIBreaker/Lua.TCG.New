local G = {}
function G.members(game)
    return game.monster and game.monster.group==game.enemies and game.enemies or game.monster and {game.monster} or {}
end
function G.count(stage,isBoss,isElite)
    if isBoss or not stage or stage<=1 then return 1 end
    return isElite and (stage%2==0 and 3 or 2) or (stage-1)%3+1
end
function G.build(primary)
    local stage=primary.stage
    local count=G.count(stage,primary.isBoss,primary.isElite)
    local enemies={primary}
    local totalHp,totalAttack=math.max(1,primary.maxHp or primary.hp or 1),math.max(1,primary.attack or 12)
    for i=2,count do
        local m={}
        for k,v in pairs(primary) do if k~="group" then m[k]=v end end
        m.intent={type="attack",value=primary.attack,label=primary.intent.label}
        m.bossData=nil;m.isBoss=false
        m.encounterCount=(primary.encounterCount or 1)+i-1
        require("src.expedition").decorate(m,stage,m.encounterCount)
        enemies[i]=m
    end
    -- Split the existing encounter budget: a squad is not three full bosses.
    local remainingHp,remainingAttack=totalHp,totalAttack
    for i,m in ipairs(enemies) do
        m.hp=i==count and remainingHp or math.max(1,math.floor(totalHp/count))
        m.maxHp=m.hp;m.damageLagHp=m.hp;remainingHp=remainingHp-m.hp
        m.attack=i==count and math.max(1,remainingAttack) or math.max(1,math.floor(totalAttack/count))
        remainingAttack=remainingAttack-m.attack
        m.intent={type="attack",value=m.attack,label="Tấn Công "..m.attack.." ST"}
        m.group=enemies;m.groupIndex=i
    end
    return enemies
end
function G.alive(enemies)
    local count=0
    for _,m in ipairs(enemies or {}) do if m.hp>0 then count=count+1 end end
    return count
end
function G.select(game,index)
    local m=game.enemies and game.enemies[index]
    if not m or m.hp<=0 then return false end
    game.monster=m;return true
end
function G.ensureTarget(game)
    if game.monster and game.monster.hp>0 then return game.monster end
    for i,m in ipairs(game.enemies or {}) do if m.hp>0 then G.select(game,i);return m end end
end
function G.rect(index,count)
    local width,height=128,192
    local center=630+(index-(count+1)/2)*176
    return center-width/2,174,width,height
end
return G
