local arithmetic = require "utils.arithmetic"
local consts = require "constants"

local function istrides(invariant, control)
    -- NOTE: `StrideCounter.value` default start is max_uint.
    control:increment()

    -- ulte because of overflow
    if arithmetic.ulte(control.value, invariant) then
        return control, control:cycle(), control:remaining_strides()
    else
        return nil
    end
end

local function iustrides(invariant, control)
    -- NOTE: `StrideCounter.value` default start is max_uint.
    control:increment()

    -- ult because we stop right before the last cycle.
    if math.ult(control.value, invariant) then
        return control, control:ucycle(), control:remaining_strides()
    else
        return nil
    end
end

local StrideCounter = {}
StrideCounter.__index = StrideCounter

function StrideCounter:new(interval, total, v)
    v = v or -1
    local s = {
        interval = interval,
        total = total,
        value = v
    }

    setmetatable(s, self)
    return s
end

function StrideCounter:increment()
    self.value = self.value + 1
end

function StrideCounter:cycle()
    local cycle = self.value << (self.interval.log2_stride - consts.a)
    return cycle
end

function StrideCounter:ucycle()
    local ucycle = self.value << self.interval.log2_stride
    return ucycle
end

function StrideCounter:remaining_strides()
    return self.total - self.value
end



local Interval = {}
Interval.__index = Interval

function Interval:new(base_meta_counter, log2_stride, log2_stride_count)
    local i = {
        base_meta_counter = base_meta_counter,
        log2_stride = log2_stride,
        log2_stride_count = log2_stride_count
    }

    setmetatable(i, self)
    return i
end

function Interval:_build_iter(log2_total_strides)
    local total_strides = arithmetic.max_int(log2_total_strides)
    local stride = StrideCounter:new(self, total_strides)
    return istrides, total_strides, stride
end

function Interval:strides()
    return self:_build_iter(self.log2_stride_count)
end

function Interval:big_strides()
    local bid_strides_in_interval
    if self.log2_stride_count >= consts.a then
        bid_strides_in_interval = self.log2_stride_count - consts.a
    else
        bid_strides_in_interval = 0
    end

    return self:_build_iter(bid_strides_in_interval)
end

function Interval:total_ucycles_in_cycle()
    local ucycles = math.min(consts.a, self.log2_stride_count)
    return arithmetic.max_int(ucycles)
end

function Interval:ucycles_in_cycle()
    local total_strides = self:total_ucycles_in_cycle()
    local stride = StrideCounter:new(self, total_strides)
    return iustrides, total_strides, stride

end

return Interval
