local bint = require "utils.bint"(256)
local Hash = require "cryptography.hash"

local ComputationCounter = {}
ComputationCounter.__index = ComputationCounter

function ComputationCounter:new(log2_stride, base_meta_counter, log2_stride_count)
    local p = {
        stride = bint(1) << log2_stride,
        stride_count = bint(1) << log2_stride_count,
        current_meta_counter = base_meta_counter,
        current_stride_count = 0,
    }

    setmetatable(p, self)
    return p
end

function ComputationCounter:is_empty()
    return self.stride_count == self.current_stride_count
end

function ComputationCounter:len()
    return self.stride_count - self.current_stride_count
end

function ComputationCounter:current()
    return self.current_meta_counter
end

function ComputationCounter:peek_next()
    if self:is_empty() then return false end
    return self.current_meta_counter + self.stride
end

function ComputationCounter:next()
    local new_meta_counter = assert(self:peek_next())
    self.current_stride_count = self.current_stride_count + 1
    self.current_meta_counter = new_meta_counter
    return new_meta_counter
end

function ComputationCounter:popn(n)
    assert(bint.ult(n, self.stride_count - self.current_stride_count))
    local new_meta_counter = self.current_meta_counter + self.stride * n
    self.current_stride_count = self.current_stride_count + n
    self.current_meta_counter = new_meta_counter
end




local remote = require "cartesi.jsonrpc"
local create_stub = remote.stub
local root_stub = create_stub("http://localhost:8080")
local v = assert(root_stub.get_version())
print(string.format("Client connected: remote version is %d.%d.%d\n", v.major, v.minor, v.patch))

local ComputationResult = {}
ComputationResult.__index = ComputationResult

function ComputationResult:new(state, halted, uhalted)
    local r = {
        state = state,
        halted = halted,
        uhalted = uhalted
    }
    setmetatable(r, self)
    return r
end

function ComputationResult:from_current_machine_state(machine)
    local hash = Hash:from_digest_bin(machine:get_root_hash())
    return ComputationResult:new(
        hash,
        machine:read_iflags_H(),
        machine:read_uarch_halt_flag()
    )
end

ComputationResult.__tostring = function(x)
    return string.format(
        "{state = %s, halted = %s, uhalted = %s}",
        x.state,
        x.halted,
        x.uhalted
    )
end

local BaseMachine = {}
BaseMachine.__index = BaseMachine

local BigMachine = {}
BigMachine.__index = BigMachine

local SmallMachine = {}
SmallMachine.__index = SmallMachine

function BaseMachine:new_root(path)
    local machine = root_stub.machine(path)
    local start_cycle = machine:read_mcycle()

    -- Machine can never be advanced on the micro arch.
    -- Validators must verify this first
    assert(machine:read_uarch_cycle() == 0)
    local b = {
        stub = root_stub,
        base_cycle = start_cycle,
    }
    setmetatable(b, self)
    return b
end

function BaseMachine:create_big_machine()
    local new_stub = assert(create_stub(self.stub.fork()))
    return BigMachine:new(self, new_stub)
end

function BaseMachine:result()
    local machine = self.stub.get_machine()
    return ComputationResult:from_current_machine_state(machine)
end


--
---
--

function BigMachine:new(base_machine, stub)
    local machine = stub.get_machine()
    assert(machine:read_mcycle() == base_machine.base_cycle)
    assert(machine:read_uarch_cycle() == 0)
    local b = {
        base_machine = base_machine,
        stub = stub,
        cycle = 0,
    }
    setmetatable(b, self)
    return b
end

function BigMachine:advance(cycle)
    local machine = self.stub.get_machine()
    machine:run(self.base_machine.base_cycle + cycle)
    self.cycle = cycle
end

function BigMachine:get_state()
    local machine = self.stub.get_machine()
    return ComputationResult:from_current_machine_state(machine)
end

function BigMachine:create_small_machine()
    local new_stub = assert(create_stub(self.stub.fork()))
    return SmallMachine:new(self, new_stub)
end

function BigMachine:shutdown()
    self.stub.shutdown()
end

function BigMachine:base_machine()
    self:shutdown()
    return self.base_machine
end



--
---
--

function SmallMachine:new(big_machine, stub)
    local machine = stub.get_machine()
    assert(machine:read_uarch_cycle() == 0)
    local b = {
        big_machine= big_machine,
        stub = stub,
        ucycle = 0,
    }
    setmetatable(b, self)
    return b
end

function SmallMachine:uadvance(ucycle)
    local machine = self.stub.get_machine()
    machine:run_uarch(ucycle)
    self.ucycle = ucycle
end

function SmallMachine:get_state()
    local machine = self.stub.get_machine()
    return ComputationResult:from_current_machine_state(machine)
end

function SmallMachine:shutdown()
    self.stub.shutdown()
end

function SmallMachine:shutdown_and_get_big_machine()
    self:shutdown()
    return self.big_machine
end


--
---
--

local consts = require "constants"

local function get_mask(k)
    return (1 << k) - 1
end

local a, b = consts.a, consts.b
local max_a, max_b = get_mask(a), get_mask(b)

local function get_ucycle(mc)
    return assert((mc & max_a):tointeger())
end

local function get_cycle(mc)
    return assert(((mc >> a) & max_b):tointeger())
end


local function add_uintervals(counter, big_machine, add_state)
    local small_machine = big_machine:create_small_machine()
    local current_instruction = get_cycle(counter:peek_next())

    while not counter:is_empty() and current_instruction == get_cycle(counter:peek_next()) do
        local next_uinstruction = get_ucycle(counter:peek_next())
        small_machine:uadvance(next_uinstruction)
        local result = small_machine:get_state()

        if result.uhalted then
            local r = bint.fromuinteger(max_a - next_uinstruction) // counter.stride + 1
            r = bint.min(r, counter:len())
            add_state(result.state, r)
            counter:popn(r)
            break
        else
            add_state(result.state)
            counter:next()
        end
    end

    small_machine:shutdown()
end

local function add_intervals(counter, base_machine, add_state)
    local big_machine = base_machine:create_big_machine()

    while not counter:is_empty() do
        local next_mc = counter:peek_next()
        local next_instruction = get_cycle(next_mc)
        big_machine:advance(next_instruction)

        if get_ucycle(next_mc) ~= 0 then
            add_uintervals(counter, big_machine, add_state)
        else
            local result = big_machine:get_state()

            if result.uhalted and counter.stride & max_a == 0 then
                local r = bint.fromuinteger(max_b - next_instruction) // counter.stride + 1
                r = bint.min(r, counter:len())
                add_state(result.state, r)
                counter:popn(r)
                assert(counter:is_empty())
                break
            else
                add_state(result.state)
                counter:next()
            end
        end
    end

    big_machine:shutdown()
end


local function get_leafs(log2_stride, base_meta_counter, log2_stride_count, base_machine)
    local interval = ComputationCounter:new(log2_stride, base_meta_counter, log2_stride_count)

    local accumulator = {}
    local function add_state(s, r)
        r = r or 1
        table.insert(accumulator, {s, r})
        print(#accumulator, s, r)
    end

    -- local cycle, ucycle = get_cycle(base_meta_counter), get_ucycle(base_meta_counter)
    -- local inital_state = base_machine:state_at(ComputationInstant:new_from_pair(cycle, ucycle)).state

    add_intervals(interval, base_machine, add_state)
    return inital_state, accumulator
end


local base_machine = BaseMachine:new_root("program/simple-program")

local mc = (bint(0)) + ((bint(0)) << 64)
local _, y = get_leafs(5, mc, 64, base_machine)

for _,v in ipairs(y) do
    print(v[1], v[2])
end
