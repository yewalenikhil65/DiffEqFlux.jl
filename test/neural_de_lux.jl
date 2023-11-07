using ComponentArrays, DiffEqFlux, Zygote, Lux, DelayDiffEq, OrdinaryDiffEq, StochasticDiffEq, Test, Random

rng = Random.default_rng()

mp = Float32[0.1,0.1]
x = Float32[2.; 0.]
xs = Float32.(hcat([0.; 0.], [1.; 0.], [2.; 0.]))
tspan = (0.0f0,1.0f0)
luxdudt = Lux.Chain(Lux.Dense(2,50,tanh),Lux.Dense(50,2))

## Lux

@info "Test some Lux layers"

node = NeuralODE(luxdudt,tspan,Tsit5(),save_everystep=false,save_start=false)
pd, st = Lux.setup(rng, node)
pd = ComponentArray(pd)
grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),x,pd,st)
@test ! iszero(grads[1])
@test ! iszero(grads[2])

grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),xs,pd,st)
@test ! iszero(grads[1])
@test ! iszero(grads[2])

#test with low tolerance ode solver
node = NeuralODE(luxdudt, tspan, Tsit5(), abstol=1e-12, reltol=1e-12, save_everystep=false, save_start=false)
grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),x,pd,st)
@test ! iszero(grads[1])
@test ! iszero(grads[2])

node = NeuralODE(luxdudt,tspan,Tsit5(),save_everystep=false,save_start=false,sensealg=TrackerAdjoint())
grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),x,pd,st)
@test ! iszero(grads[1])
@test ! iszero(grads[2])

grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),xs,pd,st)
@test ! iszero(grads[1])
@test ! iszero(grads[2])

node = NeuralODE(luxdudt,tspan,Tsit5(),save_everystep=false,save_start=false,sensealg=BacksolveAdjoint())
grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),x,pd,st)
@test ! iszero(grads[1])
@test ! iszero(grads[2])

grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),xs,pd,st)
@test ! iszero(grads[1])
@test ! iszero(grads[2])

@info "Test some adjoints"

# Adjoint
@testset "adjoint mode" begin
    node = NeuralODE(luxdudt,tspan,Tsit5(),save_everystep=false,save_start=false)
    grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),x,pd,st)
    @test ! iszero(grads[1])
    @test ! iszero(grads[2])

    grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),xs,pd,st)
    @test !iszero(grads[1])
    @test !iszero(grads[2])

    node = NeuralODE(luxdudt,tspan,Tsit5(),saveat=0.0:0.1:1.0)
    grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),x,pd,st)
    @test ! iszero(grads[1])
    @test ! iszero(grads[2])

    grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),xs,pd,st)
    @test !iszero(grads[1])
    @test !iszero(grads[2])

    node = NeuralODE(luxdudt,tspan,Tsit5(),saveat=0.1)
    grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),x,pd,st)
    @test ! iszero(grads[1])
    @test ! iszero(grads[2])

    grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),xs,pd,st)
    @test !iszero(grads[1])
    @test !iszero(grads[2])
end

@info "Test Tracker"

# RD
@testset "Tracker mode" begin
    node = NeuralODE(luxdudt,tspan,Tsit5(),save_everystep=false,save_start=false,sensealg=TrackerAdjoint())
    grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),x,pd,st)
    @test ! iszero(grads[1])
    @test ! iszero(grads[2])

    grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),xs,pd,st)
    @test ! iszero(grads[1])
    @test ! iszero(grads[2])

    node = NeuralODE(luxdudt,tspan,Tsit5(),saveat=0.0:0.1:1.0,sensealg=TrackerAdjoint())
    @test_broken grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),x,pd,st)
    @test ! iszero(grads[1])
    @test ! iszero(grads[2])

    @test_throws Any grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),xs,pd,st)
    #@test_broken ! iszero(grads[1])
    #@test_broken ! iszero(grads[2])

    node = NeuralODE(luxdudt,tspan,Tsit5(),saveat=0.1,sensealg=TrackerAdjoint())
    @test_throws Any grad = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),x,pd,st)
    #@test ! iszero(grads[1])
    #@test ! iszero(grads[2])

    @test_throws Any grads = Zygote.gradient((x,p,st)->sum(node(x,p,st)[1]),xs,pd,st)
    #@test_broken ! iszero(grads[1])
    #@test_broken ! iszero(grads[2])
end

@info "Test non-ODEs"

luxdudt2 = Lux.Chain(Lux.Dense(2,50,tanh),Lux.Dense(50,2))

sode = NeuralDSDE(luxdudt,luxdudt2,(0.0f0,.1f0),EulerHeun(),saveat=0.0:0.01:0.1,dt=0.1)
pd, st = Lux.setup(rng, sode)
pd = ComponentArray(pd)

grads = Zygote.gradient((x,p,st)->sum(sode(x,p,st)[1]),x,pd,st)
@test ! iszero(grads[1])
@test ! iszero(grads[2])
@test ! iszero(grads[2][end])

grads = Zygote.gradient((x,p,st)->sum(sode(x,p,st)[1]),xs,pd,st)
@test ! iszero(grads[1])
@test ! iszero(grads[2])
@test ! iszero(grads[2][end])

luxdudt22 = Lux.Chain(Lux.Dense(2,50,tanh),Lux.Dense(50,4),x->reshape(x,2,2))

sode = NeuralSDE(luxdudt,luxdudt22,(0.0f0,0.1f0),2,EulerHeun(),saveat=0.0:0.01:0.1,dt=0.01)
pd,st = Lux.setup(rng, sode)
pd = ComponentArray(pd)

grads = Zygote.gradient((x,p,st)->sum(sode(x,p,st)[1]),x,pd,st)
@test_broken ! iszero(grads[1])
@test_broken ! iszero(grads[2])
@test_broken ! iszero(grads[2][end])

@test_throws Any grads = Zygote.gradient((x,p,st)->sum(sode(x,p,st)),xs,pd,st)