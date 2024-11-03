--[[
Dubins curves adapted for use with AutoDrive

Copyright (c) 2008-2018, Andrew Walker

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


@Misc{DubinsCurves,
  author = {Andrew Walker},
  title  = {Dubins-Curves: an open implementation of shortest paths for the forward only car},
  year   = {2008--},
  url    = "https://github.com/AndrewWalker/Dubins-Curves"
}

]]

ADDubins = {}
function ADDubins:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.outPath = {}
    return o
end

ADDubins.DubinsPathType = {
    LSL = 1,
    LSR = 2,
    RSL = 3,
    RSR = 4,
    RLR = 5,
    LRL = 6
}

ADDubins.DubinsPath = {
    -- /* the initial configuration */
    qi = {},
    -- /* the lengths of the three segments */
    param = {},
    -- /* model forward velocity / model angular velocity */
    rho = 0,
    -- /* the path type described */
    type = 0
}

ADDubins.EDUBOK = 0
ADDubins.EDUBCOCONFIGS = 1
ADDubins.EDUBPARAM = 2
ADDubins.EDUBBADRHO = 3
ADDubins.EDUBNOPATH = 4
ADDubins.EPSILON = (10e-10)

ADDubins.SegmentType = {
    L_SEG = 0,
    S_SEG = 1,
    R_SEG = 2
}

ADDubins.DIRDATA = {
    { 0, 1, 0 },
    { 0, 1, 2 },
    { 2, 1, 0 },
    { 2, 1, 2 },
    { 2, 0, 2 },
    { 0, 2, 0 }
}

ADDubins.DubinsIntermediateResults = {
    alpha = 0,
    beta = 0,
    d = 0,
    sa = 0,
    sb = 0,
    ca = 0,
    cb = 0,
    c_ab = 0,
    d_sq = 0
}

function ADDubins:fmodr(x, y)
    return (x - y * math.floor(x/y))
end

function ADDubins:mod2pi( theta )
    return (self:fmodr( theta, 2 * math.pi ))
end

function ADDubins:dubins_shortest_path(path, q0, q1, rho)
    local inTemp = {}
    local params = {}
    local cost
    local best_cost = math.huge
    local best_word = -1
    local errcode = self:dubins_intermediate_results(inTemp, q0, q1, rho)
    if errcode ~= ADDubins.EDUBOK then
        return errcode
    end

    path.qi[1] = q0[1]
    path.qi[2] = q0[2]
    path.qi[3] = q0[3]
    path.rho = rho

    for i = 1, 6, 1 do
        errcode = ADDubins:dubins_word(inTemp, i, params)
        if errcode == ADDubins.EDUBOK then
            cost = params[1] + params[2] + params[3]
            if(cost < best_cost) then
                best_word = i
                best_cost = cost
                path.param[1] = params[1]
                path.param[2] = params[2]
                path.param[3] = params[3]
                path.type = i
            end
        end
    end
    if(best_word == -1) then
        return ADDubins.EDUBNOPATH
    end
    return ADDubins.EDUBOK
end

function ADDubins:dubins_path(path, q0, q1, rho, pathType)
    local inTemp = {}
    local errcode = ADDubins:dubins_intermediate_results(inTemp, q0, q1, rho)
    if(errcode == ADDubins.EDUBOK) then
        local params = {}
        errcode = ADDubins:dubins_word(inTemp, pathType, params)
        if(errcode == ADDubins.EDUBOK) then
            path.param[1] = params[1]
            path.param[2] = params[2]
            path.param[3] = params[3]
            path.qi[1] = q0[1]
            path.qi[2] = q0[2]
            path.qi[3] = q0[3]
            path.rho = rho
            path.type = pathType
        end
    end
    return errcode
end

function ADDubins:dubins_path_length( path )
    local length = 0
    length = length + path.param[1]
    length = length +  path.param[2]
    length = length +  path.param[3]
    length = length * path.rho;
    return length
end

function ADDubins:dubins_segment_length(  path, i )
    if( (i < 1) or (i > 3) ) then
        return math.huge
    end
    return path.param[i] * path.rho;
end

function ADDubins:dubins_segment_length_normalized( path, i )
    if( (i < 1) or (i > 3) ) then
        return math.huge
    end
    return path.param[i]
end

function ADDubins:dubins_path_type( path )
    return path.type
end

function ADDubins:dubins_segment(  t, qi, qt, type)
    local st = math.sin(qi[3])
    local ct = math.cos(qi[3])
    if( type == ADDubins.SegmentType.L_SEG ) then
        qt[1] =   math.sin(qi[3]+t) - st
        qt[2] = - math.cos(qi[3]+t) + ct
        qt[3] = t
    elseif( type == ADDubins.SegmentType.R_SEG ) then
        qt[1] = - math.sin(qi[3]-t) + st
        qt[2] =   math.cos(qi[3]-t) - ct
        qt[3] = -t
    elseif( type == ADDubins.SegmentType.S_SEG ) then
        qt[1] = ct * t
        qt[2] = st * t
        qt[3] = 0
    end
    qt[1] = qt[1] + qi[1]
    qt[2] = qt[2] + qi[2]
    qt[3] = qt[3] + qi[3]
end

function ADDubins:dubins_path_sample(  path, t, q )
    -- /* tprime is the normalised variant of the parameter t */
    local tprime = t / path.rho;
    local qi = {} --/* The translated initial configuration */
    local q1 = {} --/* end-of segment 1 */
    local q2 = {} --/* end-of segment 2 */
    local types = ADDubins.DIRDATA[path.type]
    local p1, p2

    if( t < 0 or t > self:dubins_path_length(path) ) then
        return ADDubins.EDUBPARAM
    end

    -- /* initial configuration */
    qi[1] = 0
    qi[2] = 0
    qi[3] = path.qi[3]

    -- /* generate the target configuration */
    p1 = path.param[1]
    p2 = path.param[2]
    self:dubins_segment( p1,      qi,    q1, types[1] )
    self:dubins_segment( p2,      q1,    q2, types[2] )
    if( tprime < p1 ) then
        self:dubins_segment( tprime, qi, q, types[1] )
    elseif( tprime < (p1+p2) ) then
        self:dubins_segment( tprime-p1, q1, q,  types[2] )
    else
        self:dubins_segment( tprime-p1-p2, q2, q,  types[3] )
    end

    -- /* scale the target configuration, translate back to the original starting point */
    q[1] = q[1] * path.rho + path.qi[1]
    q[2] = q[2] * path.rho + path.qi[2]
    q[3] = self:mod2pi(q[3])

    return ADDubins.EDUBOK
end

function ADDubins.createWayPoints(q, x, outPath)
    local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, q[1], 1, -q[2])
    -- print(string.format("printConfiguration xyz %.1f %.1f %.1f", q[1], y, q[2]))
    table.insert(outPath, {x = q[1], y = y, z = -q[2], t = q[3]})
    return 0
end

function ADDubins:dubins_path_sample_many(path, stepSize, cb)
    local retcode
    local q = {}
    local x = 0
    local length = self:dubins_path_length(path)
    while( x <  length ) do
        self:dubins_path_sample( path, x, q )
        retcode = cb(q, x, self.outPath)
        if( retcode ~= 0 ) then
            return retcode
        end
        x = x + stepSize
    end
    return 0
end

function ADDubins:dubins_path_endpoint( path, q )
    return self:dubins_path_sample( path, self:dubins_path_length(path) - ADDubins.EPSILON, q )
end

function ADDubins:dubins_extract_subpath( path, t, newpath )
    -- /* calculate the true parameter */
    local tprime = t / path.rho

    if ((t < 0) or (t > self:dubins_path_length(path))) then
        return ADDubins.EDUBPARAM
    end

    -- /* copy most of the data */
    newpath.qi[1] = path.qi[1]
    newpath.qi[2] = path.qi[2]
    newpath.qi[3] = path.qi[3]
    newpath.rho   = path.rho
    newpath.type  = path.type

    -- /* fix the parameters */
    newpath.param[1] = math.min( path.param[1], tprime )
    newpath.param[2] = math.min( path.param[2], tprime - newpath.param[1])
    newpath.param[3] = math.min( path.param[3], tprime - newpath.param[1] - newpath.param[2])
    return 0
end

function ADDubins:dubins_intermediate_results(inTemp, q0, q1, rho)
    local dx, dy, D, d, theta, alpha, beta
    if( rho <= 0 ) then
        return ADDubins.EDUBBADRHO
    end

    dx = q1[1] - q0[1]
    dy = q1[2] - q0[2]
    D = math.sqrt( dx * dx + dy * dy )
    d = D / rho
    theta = 0

    -- /* test required to prevent domain errors if dx=0 and dy=0 */
    if(d > 0) then
        theta = self:mod2pi(math.atan2( dy, dx ))
    end
    alpha = self:mod2pi(q0[3] - theta)
    beta  = self:mod2pi(q1[3] - theta)

    inTemp.alpha = alpha
    inTemp.beta  = beta
    inTemp.d     = d
    inTemp.sa    = math.sin(alpha)
    inTemp.sb    = math.sin(beta)
    inTemp.ca    = math.cos(alpha)
    inTemp.cb    = math.cos(beta)
    inTemp.c_ab  = math.cos(alpha - beta)
    inTemp.d_sq  = d * d

    return ADDubins.EDUBOK
end

function ADDubins:dubins_LSL( inTemp, out)
    local tmp0, tmp1, p_sq
    tmp0 = inTemp.d + inTemp.sa - inTemp.sb
    p_sq = 2 + inTemp.d_sq - (2*inTemp.c_ab) + (2 * inTemp.d * (inTemp.sa - inTemp.sb))

    if(p_sq >= 0) then
        tmp1 = math.atan2( (inTemp.cb - inTemp.ca), tmp0 )
        out[1] = self:mod2pi(tmp1 - inTemp.alpha)
        out[2] = math.sqrt(p_sq)
        out[3] = self:mod2pi(inTemp.beta - tmp1)
        return ADDubins.EDUBOK
    end
    return ADDubins.EDUBNOPATH
end

function ADDubins:dubins_RSR(inTemp, out)
    local tmp0 = inTemp.d - inTemp.sa + inTemp.sb
    local p_sq = 2 + inTemp.d_sq - (2 * inTemp.c_ab) + (2 * inTemp.d * (inTemp.sb - inTemp.sa))
    if( p_sq >= 0 ) then
        local tmp1 = math.atan2( (inTemp.ca - inTemp.cb), tmp0 )
        out[1] = self:mod2pi(inTemp.alpha - tmp1)
        out[2] = math.sqrt(p_sq)
        out[3] = self:mod2pi(tmp1 -inTemp.beta)
        return ADDubins.EDUBOK
    end
    return ADDubins.EDUBNOPATH
end

function ADDubins:dubins_LSR(inTemp, out)
    local p_sq = -2 + (inTemp.d_sq) + (2 * inTemp.c_ab) + (2 * inTemp.d * (inTemp.sa + inTemp.sb))
    if( p_sq >= 0 ) then
        local p    = math.sqrt(p_sq)
        local tmp0 = math.atan2( (-inTemp.ca - inTemp.cb), (inTemp.d + inTemp.sa + inTemp.sb) ) - math.atan2(-2.0, p)
        out[1] = self:mod2pi(tmp0 - inTemp.alpha)
        out[2] = p
        out[3] = self:mod2pi(tmp0 - self:mod2pi(inTemp.beta))
        return ADDubins.EDUBOK
    end
    return ADDubins.EDUBNOPATH
end

function ADDubins:dubins_RSL(inTemp, out)
    local p_sq = -2 + inTemp.d_sq + (2 * inTemp.c_ab) - (2 * inTemp.d * (inTemp.sa + inTemp.sb))
    if( p_sq >= 0 ) then
        local p    = math.sqrt(p_sq);
        local tmp0 = math.atan2( (inTemp.ca + inTemp.cb), (inTemp.d - inTemp.sa - inTemp.sb) ) - math.atan2(2.0, p)
        out[1] = self:mod2pi(inTemp.alpha - tmp0)
        out[2] = p
        out[3] = self:mod2pi(inTemp.beta - tmp0)
        return ADDubins.EDUBOK
    end
    return ADDubins.EDUBNOPATH
end

function ADDubins:dubins_RLR(inTemp, out)
    local tmp0 = (6. - inTemp.d_sq + 2*inTemp.c_ab + 2*inTemp.d*(inTemp.sa - inTemp.sb)) / 8
    local phi  = math.atan2( inTemp.ca - inTemp.cb, inTemp.d - inTemp.sa + inTemp.sb )
    if( math.abs(tmp0) <= 1) then
        local p = self:mod2pi((2 * math.pi) - math.acos(tmp0) )
        local t = self:mod2pi(inTemp.alpha - phi + self:mod2pi(p/2))
        out[1] = t
        out[2] = p
        out[3] = self:mod2pi(inTemp.alpha - inTemp.beta - t + self:mod2pi(p))
        return ADDubins.EDUBOK
    end
    return ADDubins.EDUBNOPATH
end

function ADDubins:dubins_LRL(inTemp, out)
    local tmp0 = (6. - inTemp.d_sq + 2*inTemp.c_ab + 2*inTemp.d*(inTemp.sb - inTemp.sa)) / 8
    local phi = math.atan2( inTemp.ca - inTemp.cb, inTemp.d + inTemp.sa - inTemp.sb )
    if( math.abs(tmp0) <= 1) then
        local p = self:mod2pi( 2 * math.pi - math.acos( tmp0) )
        local t = self:mod2pi(-inTemp.alpha - phi + p/2)
        out[1] = t
        out[2] = p
        out[3] = self:mod2pi(self:mod2pi(inTemp.beta) - inTemp.alpha -t + self:mod2pi(p))
        return ADDubins.EDUBOK
    end
    return ADDubins.EDUBNOPATH
end

function ADDubins:dubins_word(inTemp, pathType, out)
    local result
    if pathType == ADDubins.DubinsPathType.LSL then
        result = self:dubins_LSL(inTemp, out)
    elseif pathType == ADDubins.DubinsPathType.RSL then
        result = self:dubins_RSL(inTemp, out)
    elseif pathType == ADDubins.DubinsPathType.LSR then
        result = self:dubins_LSR(inTemp, out)
    elseif pathType == ADDubins.DubinsPathType.RSR then
        result = self:dubins_RSR(inTemp, out)
    elseif pathType == ADDubins.DubinsPathType.LRL then
        result = self:dubins_LRL(inTemp, out)
    elseif pathType == ADDubins.DubinsPathType.RLR then
        result = self:dubins_RLR(inTemp, out)
    end

    return result
end
