local MerkleBuilder = require "cryptography.merkle_builder"
local Machine = require "computation.machine"

local consts = require "constants"

local function build_small_machine_commitment(interval, machine)
    local outer_builder = MerkleBuilder:new()

    for _, _, remaining_big_strides in interval:big_strides() do
        local inner_builder = MerkleBuilder:new()

          for _, ucycle, remaining_strides in interval:ucycles_in_cycle() do
            machine:uadvance(ucycle)
            local state = machine:result()

            if not state.uhalted then
                inner_builder:add(state.state)
            else
                inner_builder:add(state.state, remaining_strides)
                break
            end
        end

        machine:uadvance(interval:total_ucycles_in_cycle())
        machine:ureset()
        local state = machine:result()
        inner_builder:add(state.state)

        if not state.halted then
            outer_builder:add(inner_builder:build())
        else
            outer_builder:add(inner_builder:build(), remaining_big_strides)
            break
        end
    end

    return outer_builder:build()
end

local function build_big_machine_commitment(interval, machine)
    local builder = MerkleBuilder:new()

    for _, cycle, remaining_strides in interval:strides() do
        machine:advance(cycle)
        local state = machine:result()
        if not state.halted then
            builder:add(state.state)
        else
            builder:add(state.state, remaining_strides + 1) -- this loop plus all remainings
            break
        end
    end

    return builder:build()
end

local function build_commitment(interval, path)
    local machine = Machine:new_from_path(path)
    if interval.log2_stride >= consts.a then
        return build_big_machine_commitment(interval, machine)
    else
        return build_small_machine_commitment(interval, machine)
    end
end

local bint = require "utils.bint"(256)
local Interval = require "computation.interval"
-- local Hash = require "cryptography.hash"

local mc = bint(0)
local i = Interval:new(mc, 0, 64)
local path = "program/simple-program"

local tree = build_commitment(i, path)
print(tree.root_hash)

return build_commitment
