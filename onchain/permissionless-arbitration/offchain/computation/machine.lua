local ComputationResult = require "computation.result"
local arithmetic = require "utils.arithmetic"

local cartesi = require "cartesi"

local Machine = {}
Machine.__index = Machine

function Machine:new_from_path(path)
    local machine = cartesi.machine(path)
    local start_cycle = machine:read_mcycle()

    -- Machine can never be advanced on the micro arch.
    -- Validators must verify this first
    assert(machine:read_uarch_cycle() == 0)

    local b = {
        machine = machine,
        cycle = 0,
        ucycle = 0,
        base_cycle = start_cycle,
    }

    setmetatable(b, self)
    return b
end

function Machine:result()
    return ComputationResult:from_current_machine_state(self.machine)
end

function Machine:advance(cycle)
    assert(self.cycle <= cycle)
    self.machine:run(self.base_cycle + cycle)
    self.cycle = cycle
end

function Machine:uadvance(ucycle)
    assert(arithmetic.ulte(self.ucycle, ucycle), string.format("%u, %u", self.ucycle, ucycle))
    self.machine:run_uarch(ucycle)
    self.ucycle = ucycle
end

function Machine:ureset()
    self.machine:reset_uarch_state()
    self.cycle = self.cycle + 1
    self.ucycle = 0
end

return Machine
