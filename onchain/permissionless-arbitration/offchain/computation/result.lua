local Hash = require "cryptography.hash"

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

return ComputationResult
