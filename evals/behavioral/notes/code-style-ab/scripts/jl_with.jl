using DataFrames
using CSV
using LinearAlgebra
using Statistics
using Optim
using ForwardDiff
using JLD2

df = CSV.read("Data/choices.csv", DataFrame)
@show nrow(df)
@show length(unique(df.patient_id))

################ one row per patient × option, one choice per patient ################

# reshape below assumes rows ordered patient × option
sort!(df, [:patient_id, :option_id])

n_options = 5
@show unique(combine(groupby(df, :patient_id), nrow => :n).n)
@show unique(combine(groupby(df, :patient_id), :chosen => sum => :n_chosen).n_chosen)
@show sum(df.pharmacy_id .== 0)
@show mean(df.chosen[df.pharmacy_id .!= 0]) * (n_options - 1)        # observed bupe purchase share

################ design matrix ################

df[!, :price_medicaid] = df[!, :price] .* df[!, :medicaid]

choice_cols = [:price, :price_medicaid, :distance, :default]
X = Matrix{Float64}(df[!, choice_cols])
Y = Vector{Float64}(df[!, :chosen])
O = Vector{Float64}(df[!, :pharmacy_id] .== 0)                  # outside option, utility normalized to 0

################ conditional logit by maximum likelihood ################

function likelihood(θ, X, Y, O)
    util = (X * θ) .* (1 .- O)
    U = reshape(util, n_options, :)
    P = U .- log.(sum(exp.(U), dims = 1))
    return -sum(vec(P) .* Y)
end

θ0 = zeros(length(choice_cols))
@time likelihood(θ0, X, Y, O)

result = optimize(θ -> likelihood(θ, X, Y, O), θ0, LBFGS(),
                  Optim.Options(show_trace = true, iterations = 1500, g_tol = 1e-6);
                  autodiff = Optim.ADTypes.AutoForwardDiff())
θ_hat = Optim.minimizer(result)
@show Optim.converged(result)
@show Optim.minimum(result)

H = ForwardDiff.hessian(θ -> likelihood(θ, X, Y, O), θ_hat)
se = sqrt.(diag(inv(H)))
println(DataFrame(Column_Name = choice_cols, Theta_Value = θ_hat, se = se, t = θ_hat ./ se))

@save "Estimation/Output/logit_theta.jld2" θ_hat se choice_cols

################ counterfactual bupe purchase share ################

@load "Estimation/Output/logit_theta.jld2" θ_hat se choice_cols

function purchase_share(θ; price = df.price, distance = df.distance, default = df.default)
    df_cf = DataFrame(price = price, price_medicaid = price .* df.medicaid, distance = distance, default = default)
    X_cf = Matrix{Float64}(df_cf[!, choice_cols])
    util = (X_cf * θ) .* (1 .- O)
    U = reshape(util, n_options, :)
    P = exp.(U) ./ sum(exp.(U), dims = 1)
    inside = reshape(1 .- O, n_options, :)
    return mean(sum(P .* inside, dims = 1))
end

θ_no_default = copy(θ_hat)
θ_no_default[findfirst(==(:default), choice_cols)] = 0.0

price_increase = 1.2
distance_scale = 0.5

share_baseline = purchase_share(θ_hat)
share_no_default = purchase_share(θ_no_default)
share_half_distance = purchase_share(θ_hat; distance = df.distance .* distance_scale)
share_price_up = purchase_share(θ_hat; price = df.price .* price_increase)

counterfactuals = DataFrame(
    Scenario = ["baseline", "no default advantage", "distance halved", "price +20%"],
    Purchase_Share = [share_baseline, share_no_default, share_half_distance, share_price_up])
counterfactuals[!, :Change_From_Baseline] = counterfactuals.Purchase_Share .- share_baseline
println(counterfactuals)
