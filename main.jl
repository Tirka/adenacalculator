import Printf: @printf
import Humanize: digitsep

Adena = Int

Amount = Int

Label = String

struct InvItem
    name::Label
    decompose::Union{Function, Nothing}
end

struct InvSlot
    item::InvItem
    amount::Amount
end

struct Inventory
    slots::Dict{InvItem, Amount}
end

struct Worth
    amount::Amount
    adena::Adena
end

struct MarketValue
    positions::Dict{InvItem, Worth}
    total::Adena
end

function Base.show(io::IO, mv::MarketValue)
    println(io, "┌─────┬────────────────────────────────┬───────┬──────────────┐")
    println(io, "│ Exp │                           Name │   Pcs │        Value │")
    println(io, "├─────┼────────────────────────────────┼───────┼──────────────┤")
    for (item, worth) in mv.positions
        decomposable = if isnothing(item.decompose) "-" else "+" end
        @printf(io, "│  %s  │ %30s │ %5d │ %12s │",
            decomposable, item.name, worth.amount, digitsep(worth.adena))
        println(io)
    end
    println(io, "└─────┴────────────────────────────────┴───────┴──────────────┘")
    @printf(io, "Total: %s", digitsep(mv.total))
    println(io)
end

function expand_slot(slot::InvSlot)::Dict{InvItem, Worth}
    Dict([InvSlot(item, amount) for (item, amount) in slot.item.decompose()])
end

function expand_slot(inventory::Inventory, item::InvItem)::Inventory
    new_slots = copy(inventory.slots)
    if haskey(inventory.slots, item) && !isnothing(item.decompose)
        multiplier = inventory.slots[item]
        delete!(new_slots, item)
        for (new_item, new_amount) in item.decompose()
            if !haskey(new_slots, new_item)
                new_slots[new_item] = 0
            end
            new_slots[new_item] += new_amount * multiplier
        end
    end
    Inventory(new_slots)
end

function calculate_price(inventory::Inventory)::Union{MarketValue, Nothing}
    positions = Dict()
    for (item, amount) in inventory.slots
        base_price = get_base_price(item)
        positions[item] = Worth(amount, amount * base_price)
    end
    total = reduce(+, map(x -> x.adena, values(positions)))
    MarketValue(positions, total)
end

function get_base_price(item::InvItem)::Adena
    items_price = Dict(
        ANIMAL_BONE =>                800,
        ASOFE =>                      25_000,
        BLACKSMITHS_FRAME =>          500_000,
        BLUE_WOLF_GAITERS_MATERIAL => 100_000,
        BRAIDED_HEMP =>               2_500,
        CHARCOAL =>                   500,
        COAL =>                       500,
        COARSE_BONE_POWDER =>         8_000,
        COKES =>                      5_000,
        CRYSTAL_B_GRADE =>            13_500,
        GEMSTONE_B =>                 14_444,
        IRON_ORE =>                   800,
        MAESTRO_MOLD =>               1_000_000,
        MITHRIL_ALLOY =>              100_000,
        MITHRIL_ORE =>                7_000,
        MOLD_GLUE =>                  30_000,
        RECIPE_BLUE_WOLF_GAITERS =>   750_000,
        SILVER_MOLD =>                100_000,
        SILVER_NUGGET =>              1_000,
        STEEL =>                      5_000,
        STEM =>                       500,
        STONE_OF_PURITY =>            40_000,
        VARNISH_OF_PURITY =>          65_000,
        VARNISH =>                    900,
    )

    get!(items_price, item, 0)
end


const ANIMAL_BONE =                 InvItem("Animal Bone", nothing)
const ASOFE =                       InvItem("Asofe", nothing)
const BLACKSMITHS_FRAME =           InvItem("Blacksmith's Frame", () -> [
                                        (MITHRIL_ORE, 10)
                                        (SILVER_MOLD, 1)
                                        (VARNISH_OF_PURITY, 5)
                                    ])
const BLUE_WOLF_GAITERS_MATERIAL =  InvItem("Blue Wolf Gaiters Material", nothing)
const BRAIDED_HEMP =                InvItem("Braided Hemp", () -> [
                                        (STEM, 5)
                                    ])
const CHARCOAL =                    InvItem("Charcoal", nothing)
const COAL =                        InvItem("Coal", nothing)
const COARSE_BONE_POWDER =          InvItem("Coarse Bone Powder", () -> [
                                        (ANIMAL_BONE, 10)
                                    ])
const COKES =                       InvItem("Cokes", () -> [
                                        (COAL, 3)
                                        (CHARCOAL, 3)
                                    ])
const CRYSTAL_B_GRADE =             InvItem("Crystal: B-Grade", nothing)
const GEMSTONE_B =                  InvItem("Gemstone B", nothing)
const IRON_ORE =                    InvItem("Iron Ore", nothing)
const MAESTRO_MOLD =                InvItem("Maestro Mold", () -> [
                                        (BLACKSMITHS_FRAME, 1)
                                        (MOLD_GLUE, 10)
                                        (ASOFE, 5)
                                    ])
const MITHRIL_ALLOY =               InvItem("Mithril Alloy", () -> [
                                        (MITHRIL_ORE, 1)
                                        (STEEL, 2)
                                        (VARNISH_OF_PURITY, 1)
                                    ])
const MITHRIL_ORE =                 InvItem("Mithril Ore", nothing)
const MOLD_GLUE =                   InvItem("Mold Glue", nothing)
const RECIPE_BLUE_WOLF_GAITERS =    InvItem("Recipe: Blue Wolf's Gaiters", nothing)
const SILVER_MOLD =                 InvItem("Silver Mold", () -> [
                                        (SILVER_NUGGET, 10)
                                        (BRAIDED_HEMP, 5)
                                        (COKES, 5)
                                    ])
const SILVER_NUGGET =               InvItem("Silver Nugget", nothing)
const STEEL =                       InvItem("Steel", () -> [
                                        (VARNISH, 5)
                                        (IRON_ORE, 5)
                                    ])
const STEM =                        InvItem("Stem", nothing)
const STONE_OF_PURITY =             InvItem("Stone of Purity", nothing)
const VARNISH_OF_PURITY =           InvItem("Varmish of Purity", () -> [
                                        (VARNISH, 3)
                                        (STONE_OF_PURITY, 1)
                                        (COARSE_BONE_POWDER, 3)
                                    ])
const VARNISH =                     InvItem("Varmish", nothing)

blue_wolf_gaiters = Inventory(Dict([
    CRYSTAL_B_GRADE => 25
    MITHRIL_ALLOY => 36
    GEMSTONE_B => 12
    ASOFE => 24
    MAESTRO_MOLD => 2
    BLUE_WOLF_GAITERS_MATERIAL => 13
    RECIPE_BLUE_WOLF_GAITERS => 1
]))

println(calculate_price(blue_wolf_gaiters))

blue_wolf_gaiters2 = expand_slot(blue_wolf_gaiters, MITHRIL_ALLOY)

println(calculate_price(blue_wolf_gaiters2))
