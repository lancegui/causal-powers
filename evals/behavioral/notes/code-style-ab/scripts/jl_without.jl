# Logit_Choice.jl — conditional logit of pharmacy choice with an outside option.
#
# Model: patient i picks one of J = 4 inside options (pharmacies) or the outside
# option (no purchase, j = 0). Indirect utility of inside option j is
#
#     V_ij = β_p · price_ij + β_pm · price_ij · medicaid_i + β_d · distance_ij + β_def · default_ij
#
# and V_i0 = 0 (outside option normalized). Choice probabilities are
# P_ij = exp(V_ij) / (1 + Σ_k exp(V_ik)), estimated by ML with Optim/LBFGS and
# forward-mode AD; standard errors from the inverse Hessian of the negative
# log-likelihood. Then: buprenorphine purchase share (mass on any inside option,
# averaged over patients) under baseline and three counterfactuals.
#
# Run from the project root:
#   julia --project=<env> Estimation/Logit_Choice.jl

using CSV, DataFrames, Optim, ForwardDiff, JLD2, LinearAlgebra, Statistics, Printf

const ROOT    = normpath(joinpath(@__DIR__, ".."))
const INFILE  = joinpath(ROOT, "Data", "choices.csv")
const OUTDIR  = joinpath(ROOT, "Estimation", "Output")
const OUTFILE = joinpath(OUTDIR, "logit_theta.jld2")
const J       = 4                                   # inside options per patient
const PARNAMES = ["price", "price x medicaid", "distance", "default"]

# ----------------------------------------------------------------------------
# 1. Load and validate the data contract
# ----------------------------------------------------------------------------
df = CSV.read(INFILE, DataFrame)
sort!(df, [:patient_id, :option_id])

required = [:patient_id, :option_id, :pharmacy_id, :price, :distance, :default, :medicaid, :chosen]
@assert all(c -> c in propertynames(df), required) "choices.csv is missing required columns"
@assert !any(ismissing, Matrix(df[:, required])) "missing values in choices.csv"

g = groupby(df, :patient_id)
rows_per_patient = combine(g, nrow => :n, :chosen => sum => :nchosen,
                           :medicaid => (x -> length(unique(x))) => :nmed,
                           :pharmacy_id => (x -> count(==(0), x)) => :nout)
@assert all(rows_per_patient.n .== J + 1)     "every patient must have exactly $(J+1) rows (4 inside + outside)"
@assert all(rows_per_patient.nchosen .== 1)   "every patient must have exactly one chosen row"
@assert all(rows_per_patient.nmed .== 1)      "medicaid must be constant within patient"
@assert all(rows_per_patient.nout .== 1)      "every patient must have exactly one outside option (pharmacy_id == 0)"

outside = df[df.pharmacy_id .== 0, :]
inside  = df[df.pharmacy_id .!= 0, :]
@assert all(outside.price .== 0) && all(outside.distance .== 0) && all(outside.default .== 0) "outside option must carry zero attributes"
@assert all(inside.price .> 0) && all(inside.distance .>= 0) "inside prices must be positive, distances non-negative"
@assert all(x -> x in (0, 1), inside.default) && all(x -> x in (0, 1), df.medicaid) && all(x -> x in (0, 1), df.chosen)

N = nrow(rows_per_patient)
@assert nrow(inside) == N * J

# Patient-major arrays: N × J for option attributes, N for patient attributes
sort!(inside, [:patient_id, :option_id])
price    = reshape(Float64.(inside.price),    J, N) |> permutedims
dist     = reshape(Float64.(inside.distance), J, N) |> permutedims
default  = reshape(Float64.(inside.default),  J, N) |> permutedims
Ych      = reshape(Float64.(inside.chosen),   J, N) |> permutedims   # 1 if inside option j chosen
pid      = reshape(inside.patient_id, J, N)[1, :]
medicaid = Float64.(combine(groupby(inside, :patient_id), :medicaid => first => :m).m)
@assert length(medicaid) == N && issorted(pid)
@assert all(sum(Ych, dims = 2) .<= 1)

n_inside_chosen = Int(sum(Ych))
observed_share  = n_inside_chosen / N
println("Loaded $N patients × $J inside options; $(n_inside_chosen) bought ($(round(100*observed_share, digits=1))%), ",
        "$(N - n_inside_chosen) chose the outside option.")
println("Medicaid share of patients: $(round(100*mean(medicaid), digits=1))%")

# ----------------------------------------------------------------------------
# 2. Likelihood (AD-friendly, log-sum-exp stabilized)
# ----------------------------------------------------------------------------
"""
    utilities(θ, price, dist, default, medicaid; price_mult, dist_mult, default_on)

N × J matrix of inside-option utilities. Outside utility is 0 by normalization.
"""
function utilities(θ, price, dist, default, medicaid; price_mult = 1.0, dist_mult = 1.0, default_on = true)
    β_p, β_pm, β_d, β_def = θ
    P = price .* price_mult
    β_def_eff = default_on ? β_def : zero(β_def)
    return β_p .* P .+ β_pm .* (P .* medicaid) .+ β_d .* (dist .* dist_mult) .+ β_def_eff .* default
end

# log(1 + Σ_j exp(V_ij)) per patient, stabilized
function logsumexp0(V)
    mx = max.(zero(eltype(V)), maximum(V, dims = 2))
    return vec(mx .+ log.(exp.(-mx) .+ sum(exp.(V .- mx), dims = 2)))
end

function loglik(θ, price, dist, default, medicaid, Ych)
    V   = utilities(θ, price, dist, default, medicaid)
    lse = logsumexp0(V)
    vch = vec(sum(V .* Ych, dims = 2))          # utility of the chosen option (0 if outside)
    return sum(vch .- lse)
end

# Inside (purchase) share: mean over patients of 1 - P_i0 = 1 - exp(-lse_i)
function inside_share(θ, price, dist, default, medicaid; kwargs...)
    V   = utilities(θ, price, dist, default, medicaid; kwargs...)
    lse = logsumexp0(V)
    return mean(1 .- exp.(-lse))
end

nll(θ) = -loglik(θ, price, dist, default, medicaid, Ych)

# ----------------------------------------------------------------------------
# 3. Estimate by ML: LBFGS with forward-mode AD
# ----------------------------------------------------------------------------
θ0  = zeros(length(PARNAMES))
ll0 = -nll(θ0)
# Gradient by forward-mode AD (ForwardDiff), handed to Optim explicitly
const GRADCFG = ForwardDiff.GradientConfig(nll, θ0)
nll_grad!(G, θ) = ForwardDiff.gradient!(G, nll, θ, GRADCFG)
res = optimize(nll, nll_grad!, θ0, LBFGS(),
               Optim.Options(g_tol = 1e-8, iterations = 1_000, show_trace = false); inplace = true)
θ̂  = Optim.minimizer(res)
ll̂ = -Optim.minimum(res)
grad_norm = norm(ForwardDiff.gradient(nll, θ̂), Inf)

println("\nOptim status: converged = $(Optim.converged(res)), iterations = $(Optim.iterations(res)), ",
        "|grad|_inf = $(@sprintf("%.2e", grad_norm))")
@assert Optim.converged(res) "LBFGS did not converge"
@assert grad_norm < 1e-4     "gradient at optimum is not small"
@assert ll̂ > ll0             "optimum must improve on the null (θ = 0) log-likelihood"

# Standard errors from the Hessian of the negative log-likelihood
H = ForwardDiff.hessian(nll, θ̂)
@assert isposdef(Symmetric(H)) "Hessian at the optimum is not positive definite — not a local minimum"
vcov = inv(Symmetric(H))
se   = sqrt.(diag(vcov))
z    = θ̂ ./ se

# Interpretable units: dollar equivalents via the non-Medicaid price coefficient
dollar_equiv = θ̂ ./ (-θ̂[1])

println("\nConditional logit estimates (outside option utility = 0), N = $N patients")
println(rpad("parameter", 20), lpad("estimate", 12), lpad("std.err", 12), lpad("z", 10), lpad("\$-equiv", 12))
println("-"^66)
for k in eachindex(θ̂)
    @printf("%-20s%12.5f%12.5f%10.2f%12.2f\n", PARNAMES[k], θ̂[k], se[k], z[k], dollar_equiv[k])
end
println("-"^66)
@printf("log-likelihood at θ=0: %.3f   at θ̂: %.3f   pseudo-R2: %.4f\n", ll0, ll̂, 1 - ll̂ / ll0)
println("(\$-equiv = coefficient / -β_price: willingness to pay in \$ per unit, for non-Medicaid patients)")
println("Medicaid price coefficient: $(round(θ̂[1] + θ̂[2], digits=5)) (= β_price + β_price×medicaid)")

# ----------------------------------------------------------------------------
# 4. Save estimates
# ----------------------------------------------------------------------------
mkpath(OUTDIR)
jldsave(OUTFILE; theta = θ̂, se = se, vcov = vcov, names = PARNAMES,
        loglik = ll̂, loglik_null = ll0, N = N, J = J, converged = Optim.converged(res))
chk = load(OUTFILE)
@assert chk["theta"] == θ̂ && chk["names"] == PARNAMES "saved estimates do not round-trip"
println("\nSaved estimates to $(relpath(OUTFILE, ROOT))")

# ----------------------------------------------------------------------------
# 5. Counterfactual purchase shares
# ----------------------------------------------------------------------------
share_base = inside_share(θ̂, price, dist, default, medicaid)
share_a    = inside_share(θ̂, price, dist, default, medicaid; default_on = false)   # (a) no default advantage
share_b    = inside_share(θ̂, price, dist, default, medicaid; dist_mult = 0.5)      # (b) distance halved
share_c    = inside_share(θ̂, price, dist, default, medicaid; price_mult = 1.2)     # (c) price +20%

# Sanity: the fitted inside share should be close to the observed one
@printf("\nObserved purchase share: %.4f   Predicted (baseline): %.4f\n", observed_share, share_base)

scen = [("Baseline",                    share_base),
        ("(a) No default advantage",    share_a),
        ("(b) Distance halved",         share_b),
        ("(c) Price +20%",              share_c)]

println("\nPredicted buprenorphine purchase share (mass on any inside option, mean over patients)")
println(rpad("scenario", 28), lpad("share", 10), lpad("Δ vs base", 12), lpad("Δ (pp)", 10))
println("-"^60)
for (name, s) in scen
    @printf("%-28s%10.4f%12.4f%10.2f\n", name, s, s - share_base, 100 * (s - share_base))
end
println("-"^60)
