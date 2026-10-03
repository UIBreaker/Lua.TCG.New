local Combat=require("src.combat")
local Monster=require("src.monster")
local Group=require("src.enemy_group")
local Trait=require("src.enemy_abilities")
local Run=require("src.run_manager")
local Deck=require("src.deck")
local Game=require("src.game_state")
local Persistence=require("src.persistence")
local function start(stage,boss,elite)
    local g=Game.new("red_deck");g.persistentDeck={Deck.newCard(3,"clubs"),Deck.newCard(8,"hearts"),Deck.newCard(11,"diamonds")}
    local blind=Run.generateAnteBlinds(stage)[boss and 3 or elite and 2 or 1]
    Combat.start(g,Run.createBlindMonster(blind,g),stage)
    return g,blind
end
for stage=1,80 do
    for _,type in ipairs({"small","big","boss"}) do
        local g,b=start(stage,type=="boss",type=="big")
        local expected=Group.count(stage,type=="boss",type=="big")
        assert(#g.enemies==expected and expected>=1 and expected<=3)
        local hp,atk=0.0,0
        for i,m in ipairs(g.enemies) do
            assert(m.groupIndex==i and m.group==g.enemies)
            hp=hp+m.hp;atk=atk+m.attack
            if stage>40 then assert(m.creatureCard and m.cardRank>=2 and m.cardRank<=13 and m.enemyAbility) end
        end
        assert(math.abs(hp-b.hp)<=math.max(1e-7,b.hp*1e-14),"squad must preserve encounter HP budget")
        assert(atk==Monster.getAttackByEncounter((stage-1)*3+b.index,type=="boss",type=="big"))
    end
end
local g=start(3)
assert(#g.enemies==3)
assert(Group.select(g,2) and g.monster==g.enemies[2])
local _,won=Monster.takeDamage(g.monster,g.monster.hp)
assert(not won and Combat.getOutcome(g)=="continue","one kill is not encounter victory")
assert(not Group.select(g,2),"dead enemy cannot be targeted")
Group.ensureTarget(g);assert(g.monster==g.enemies[1])
Monster.takeDamage(g.monster,g.monster.hp)
assert(Combat.getOutcome(g)=="continue")
Group.ensureTarget(g)
local _,done=Monster.takeDamage(g.monster,g.monster.hp)
assert(done and Combat.getOutcome(g)=="victory")
-- Speed ordering: fast enemies act before; slow enemies after; dead enemies never act.
g=start(3);g.lastPlayerAttackSpeed=5
g.enemies[1].attackSpeed=9;g.enemies[2].attackSpeed=3;g.enemies[3].hp=0
local before=Combat.resolveMonsterAttack(g,"before",5)
local after=Combat.resolveMonsterAttack(g,"after",5)
assert(before.attackerCount==1 and after.attackerCount==1)
assert(g.enemies[1].attack>1 and g.monster==g.enemies[1])
-- Every trait changes actual HP, armor, gold, poison or attack strength.
local function creature(key,rank)
    local m=Monster.create(41,false,false,1)
    m.artKey=key;Trait.attach(m);m.cardRank=rank or 2
    m.hp=100;m.maxHp=100;m.attack=10;m.group=nil;Trait.start(m)
    return m
end
local golem=creature("lava_golem");assert(golem.creatureArmor==12)
local damage=Monster.takeDamage(golem,20);assert(damage==8 and golem.hp==92 and golem.creatureArmor==0)
Trait.afterAttack(g,golem,10);assert(golem.creatureArmor==3)
local skeleton=creature("ancient_skeleton")
assert(not select(2,Monster.takeDamage(skeleton,100)) and skeleton.hp==25)
assert(select(2,Monster.takeDamage(skeleton,25)) and skeleton.hp==0,"revive only once")
local wraith=creature("swamp_wraith");wraith.hp=40
Trait.afterAttack(g,wraith,20);assert(wraith.hp>40 and wraith.hp<=100)
local goblin=creature("forest_goblin");g.gold=2
Trait.afterAttack(g,goblin,5);assert(g.gold==2)
Trait.afterAttack(g,goblin,5);assert(g.gold==1)
local scorpion=creature("desert_scorpion",11);g.enemyPoison=0
Trait.afterAttack(g,scorpion,0);assert(g.enemyPoison==0,"blocked hits cannot poison")
Trait.afterAttack(g,scorpion,4);assert(g.enemyPoison==2)
g.abilityHand=nil;g.hand={};g.playerHp=100
Trait.handEnd(g);assert(g.playerHp==98 and g.enemyPoison==1)
local wolf=creature("frost_wolf");g.monster=wolf;g.enemies={wolf,golem,goblin};wolf.group=g.enemies
assert(Trait.attackBonus(g,wolf)==4);goblin.hp=0;assert(Trait.attackBonus(g,wolf)==2)
g.enemies={};g.monster=wolf
assert(Trait.attackBonus(g,wolf)==0,"stale enemy lists cannot grant pack bonuses")
local saved=Persistence.makeSnapshot(g,"BLIND_SELECT")
assert(not saved.game.enemies and not saved.game.enemyPoison,"transient groups are not serialized")
local x,y,w,h=Group.rect(1,3);assert(w==128 and h==192 and x>300 and y+h<420)
print("Enemy group smoke passed: 240 encounters, 1–3 enemies, budget, targeting, victory, speed, six real traits, ranks, save safety and compact layout")
