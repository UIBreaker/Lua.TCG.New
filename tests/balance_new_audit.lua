-- Read-only balance experiment: runtime overrides live only in this process.
local Audit={}
function Audit.run(bot)
    local G=require("src.game_state")
    local Run=require("src.run_manager")
    local Shop=require("src.shop")
    local Reward=require("src.reward_system")
    local Deck=require("src.deck")
    local Group=require("src.enemy_group")
    local R=require("src.rng")
    local seeds,prefix=200,"docs/balance_audit"
    assert(Shop.PRICE_MULTIPLIER==4 and Run.calculateBlindHp(1,"small")==100,"audit must start from the shipped balance")
    for _,v in ipairs(arg or {}) do
        seeds=tonumber(v:match("^%-%-sim%-seeds=(%d+)$")) or seeds
        prefix=v:match("^%-%-sim%-out=(.+)$") or prefix
    end
    assert(seeds>=1 and seeds<=1000 and prefix:match("^docs/[%w_/-]+$") and not prefix:find("..",1,true))
    local function write(suffix,rows)
        local f=assert(io.open(prefix..suffix..".csv","w"));f:write(table.concat(rows,"\n"),"\n");f:close()
    end
    local opening={"opening_hp,policy,seed,encounter,won,hp,turns,hits,misses,aura_mean,timeout"}
    for _,hp in ipairs({100}) do for _,smart in ipairs({false,true}) do
        local wins={0,0,0}
        for seed=1,seeds do
            local g=bot.newGame(80000+seed)
            g.consumables={Shop.healingItem(nil,"healing_potion").consumable,
                Shop.healingItem(nil,"armor_potion_small").consumable,Shop.healingItem(nil,"cons_speed_small").consumable}
            local blinds=Run.generateAnteBlinds(1,"red_deck","human",1)
            for index,b in ipairs(blinds) do
                b.hp=math.floor(hp*(index==1 and 1 or index==2 and 1.5 or 2)+.5)
                R.seed(80000000+seed*10+index)
                local s=bot.fight(g,b,smart,{preview=smart,supplies=true})
                local sum=0;for _,v in ipairs(s.auras) do sum=sum+v end
                opening[#opening+1]=table.concat({hp,smart and "tactical" or "greedy",seed,index,s.won and 1 or 0,
                    math.floor(g.playerHp),s.turns,s.hits,s.misses,math.floor(sum/math.max(1,#s.auras)),s.timeout and 1 or 0},",")
                if not s.won then break end
                wins[index]=wins[index]+1
            end
        end
        print(string.format("Opening %d/%s: first %d/%d, full first stage %d/%d",hp,smart and "tactical" or "greedy",wins[1],seeds,wins[3],seeds))
    end end
    write("_opening",opening)

    local wealth={"policy,unused_hands,seed,fight,stage,gold,souls,spent,strong_bought,free_strong"}
    local offers={"policy,unused_hands,seed,fight,stage,mode,group,currency,cost,gold,souls,afford_current,free"}
    local rank={common=1,uncommon=2,rare=3,epic=4,legendary=5,mythic=6,transcendent=7,unique=8,eternal=9,supreme=10}
    local function class(item)
        if item.category=="deity" then return (rank[item.rarity or item.deity.rarity] or 1)>=4 and "spn_epic_plus" or "spn_low" end
        if item.category=="equipment" then
            local eq=item.equipment
            if eq.soulOnly then return "soul_relic" end
            if (eq.craftTier or 0)>=4 then return "gear_tier4_plus" end
            if not eq.basic then return "gear_other" end
            return "material"
        end
        if item.category=="card" then return (item.card.evolutionLevel or 0)>=2 and "card_evolution2" or "card_other" end
        return item.category
    end
    local function valuable(item)
        local c=class(item)
        return c=="spn_epic_plus" or c=="gear_tier4_plus" or c=="soul_relic" or c=="card_evolution2"
    end
    for _,policy in ipairs({"save","shopper"}) do for _,unused in ipairs(policy=="save" and {0,2} or {0}) do
        for seed=1,seeds do
            R.seed(90000+seed)
            local g=G.new("red_deck");g.run=Run.newRun("red_deck");g.persistentDeck=Deck.createRedStarterDeck()
            local shop=Shop.new();local spent,strongBought,freeStrong=0,0,0
            for stage=1,20 do
                g.run.ante=stage;g.run.areaStage=stage
                g.run.blinds=Run.generateAnteBlinds(stage,"red_deck","human",stage)
                for index,blind in ipairs(g.run.blinds) do
                    local fight=(stage-1)*3+index
                    g.run.currentBlindIndex=index;g.handsRemaining=unused;g.enemies={}
                    for i=1,Group.count(stage,index==3,index==2) do g.enemies[i]={hp=0,maxHp=1,isBoss=index==3} end
                    g.monster=g.enemies[1];g.monster.group=g.enemies;g.monster.bossData=blind.debuff
                    g.lastRoundDeityRewards={bonusGold=0,details={}};g.pendingVictoryReward=nil
                    Reward.begin(Reward.calculate(blind,g),g)
                    g.run.stats.blindsWon=g.run.stats.blindsWon+1
                    assert(g.gold>=0 and g.souls>=0)
                    Shop.enterAfterCombat(g);Shop.resetReroll(shop);Shop.refresh(shop,g)
                    local function visit()
                        for _,item in ipairs(shop.items) do
                            local c=class(item)
                            offers[#offers+1]=table.concat({policy,unused,seed,fight,stage,g.shopMode,c,item.currency or "gold",item.cost,
                                g.gold,g.souls,Shop.canAfford(item,g) and 1 or 0,
                                item.cost==0 and 1 or 0},",")
                        end
                        if policy~="shopper" then return end
                        -- One useful paid purchase per visit; collect free equipment as well.
                        local selected,best=nil,-1
                        for i,item in ipairs(shop.items) do
                            if Shop.canAfford(item,g) then
                                local c=class(item)
                                local value=valuable(item) and 100 or c=="gear_other" and 60 or c=="spn_low" and 40 or 0
                                if value>0 then value=value-item.cost*.04 end
                                if value>best and value>0 then selected,best=i,value end
                            end
                        end
                        if selected then
                            local item=shop.items[selected]
                            local field=item.currency=="blood" and "playerHp" or item.currency=="souls" and "souls" or "gold"
                            local before=g[field]
                            if Shop.buyItem(shop,selected,g) then
                                assert(g[field]==before-item.cost,"economic probe must charge the displayed price")
                                if not item.currency then spent=spent+item.cost end
                                if valuable(item) then strongBought=strongBought+1;if item.cost==0 then freeStrong=freeStrong+1 end end
                            end
                        end
                        for i=#shop.items,1,-1 do
                            local item=shop.items[i]
                            if item.cost==0 and item.category=="equipment" then
                                if Shop.buyItem(shop,i,g) and valuable(item) then strongBought=strongBought+1;freeStrong=freeStrong+1 end
                            end
                        end
                    end
                    visit()
                    if g.shopMode=="soul" then
                        g.shopMode="large";Shop.resetReroll(shop);Shop.refresh(shop,g);visit()
                        if g.pendingBloodShop then g.shopMode=g.pendingBloodShop;g.pendingBloodShop=nil;Shop.refresh(shop,g);visit() end
                    end
                    wealth[#wealth+1]=table.concat({policy,unused,seed,fight,stage,g.gold,g.souls,spent,strongBought,freeStrong},",")
                end
            end
        end
        print("Economy "..policy.."/unused "..unused..": "..seeds.." complete 60-win routes")
    end end
    write("_economy",wealth);write("_offers",offers)
    print("Balance audit exported: "..prefix.."_{opening,economy,offers}.csv")
    return true
end
return Audit
