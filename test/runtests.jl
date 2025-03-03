using Test
using SimSpread
using NamedArrays
using MLBase

# TODO: Add general utilities unit tests
#=
@testset "General utilities" begin
    read_namedmatrix
    k,
end
=#

@testset "SimSpread Core" begin
    @testset "prepare" begin
        # Prepare test
        DF = NamedArray([1 0 1; 1 1 0; 0 1 1])
        DT = NamedArray([0 1; 1 1; 1 0])
        C = ["D1"]
        setnames!(DF, ["D$i" for i in 1:3], 1)
        setnames!(DF, ["fD$i" for i in 1:3], 2)
        setnames!(DT, ["D$i" for i in 1:3], 1)
        setnames!(DT, ["T$i" for i in 1:2], 2)

        @testset "Graph construction" begin
            A, B = prepare(DT, DF, C)
            @test all(names(A, 1) .== names(A, 2))
            @test all(names(B, 1) .== names(B, 2))
            @test all(names(A, 1) .== ["D1", "D2", "D3", "fD2", "fD3", "T1", "T2"])
            @test all(names(B, 1) .== ["D1", "D2", "D3", "fD2", "fD3", "T1", "T2"])
        end

        @testset "Graph construction errors" begin
            setnames!(DF, ["D$i" for i in 1:3], 2)
            @test_throws AssertionError("Features and drugs have the same names!") prepare(DT, DF, C)
        end
    end

    @testset "cutoff" begin
        # Prepare test
        x = 0.8
        y = 0.2
        z = hcat(collect(0.0:0.1:1.0))

        @testset "Cutoff = mean(values)" begin
            α = 0.5
            @test cutoff(x, α, false) ≈ 1.0
            @test cutoff(x, α, true) ≈ 0.8
            @test cutoff(y, α, false) ≈ 0.0
            @test cutoff(y, α, true) ≈ 0.0
            @test cutoff(z, α, false) ≈ [0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
            @test cutoff(z, α, true) ≈ [0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
        end

        @testset "Cutoff < min(values)" begin
            β = -0.01
            @test cutoff(x, β, false) ≈ 1.0
            @test cutoff(x, β, true) ≈ 0.8
            @test cutoff(y, β, false) ≈ 1.0
            @test cutoff(y, β, true) ≈ 0.2
            @test cutoff(z, β, false) ≈ ones(Float64, 11)
            @test cutoff(z, β, true) ≈ z
        end

        @testset "Cutoff > max(values)" begin
            γ = 1.01
            @test cutoff(x, γ, false) ≈ 0.0
            @test cutoff(x, γ, true) ≈ 0.0
            @test cutoff(y, γ, false) ≈ 0.0
            @test cutoff(y, γ, true) ≈ 0.0
            @test cutoff(z, γ, false) ≈ zeros(Float64, 11)
            @test cutoff(z, γ, true) ≈ zeros(Float64, 11)
        end
    end
end

# TODO: Add performance metrics unit tests
@testset "Performance evaluation" begin
    @testset "Overall performance metrics" begin end
    @testset "Early recognition metrics" begin end
    @testset "Binary prediction metrics" begin
        @testset "From confusion matrix" begin
            tn, fp, fn, tp = [3, 2, 2, 3]

            @test SimSpread.f1score(tn, fp, fn, tp) ≈ 0.6
            @test SimSpread.mcc(tn, fp, fn, tp) ≈ 0.2
            @test SimSpread.accuracy(tn, fp, fn, tp) ≈ 0.6
            @test SimSpread.balancedaccuracy(tn, fp, fn, tp) ≈ 0.6
            @test SimSpread.recall(tn, fp, fn, tp) ≈ 0.6
            @test SimSpread.precision(tn, fp, fn, tp) ≈ 0.6
        end

        @testset "From y and ŷ vectors" begin
            y, yhat = [1, 1, 0, 1, 0, 0, 0, 1, 1, 0], [1, 1, 1, 1, 1, 0, 0, 0, 0, 0]

            @test SimSpread.f1score(roc(y, yhat)) ≈ 0.6
            @test SimSpread.mcc(roc(y, yhat)) ≈ 0.2
            @test SimSpread.accuracy(roc(y, yhat)) ≈ 0.6
            @test SimSpread.balancedaccuracy(roc(y, yhat)) ≈ 0.6
            @test SimSpread.recall(roc(y, yhat)) ≈ 0.6
            @test SimSpread.precision(roc(y, yhat)) ≈ 0.6
        end

        @testset "MCC for undefined cases" begin
            yhat, y = [1, 1, 0, 1, 0, 0, 0, 1, 1, 0], [1, 1, 1, 0, 0, 0, 0, 0, 0, 0]

            @test SimSpread.mcc(roc(y, ones(Int, 10))) - SimSpread.mcc(5, 5) < 10^-5
            @test SimSpread.mcc(roc(y, zeros(Int, 10))) - SimSpread.mcc(5, 5) < 10^-5
            @test SimSpread.mcc(roc(ones(Int, 10), yhat)) - SimSpread.mcc(5, 5) < 10^-5
            @test SimSpread.mcc(roc(zeros(Int, 10), yhat)) - SimSpread.mcc(5, 5) < 10^-5
        end
    end
end
