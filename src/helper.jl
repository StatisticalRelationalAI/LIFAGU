using Random, Serialization

@isdefined(FactorGraph)      || include(string(@__DIR__, "/factor_graph.jl"))
@isdefined(color_passing)    || include(string(@__DIR__, "/color_passing.jl"))
@isdefined(colors_to_groups) || include(string(@__DIR__, "/fg_to_pfg.jl"))

"""
	load_from_file(path::String)

Load a serialized object from the given file.
"""
function load_from_file(path::String)
	io = open(path, "r")
	obj = deserialize(io)
	close(io)
	return obj
end

"""
	save_to_file(obj, path::String)

Serialize an object to a given file.
"""
function save_to_file(obj, path::String)
	open(path, "w") do io
		serialize(io, obj)
	end
end

"""
	add_noise!(potentials::Dict, epsilon::Float64)

Add noise to the given potentials.
"""
function add_noise!(potentials::Dict, epsilon::Float64)
	for (key, _) in potentials
		potentials[key] += epsilon
	end
end

"""
	delete_potentials!(fg::FactorGraph, k::Int, seed::Int=123)

Delete `k` potentials from the given factor graph `fg` such that for each
unknown factor there exists at least one known factor from the same group.
If it is not possible to delete `k` potentials in total, as many potentials
as possible are deleted.
"""
function delete_potentials!(fg::FactorGraph, k::Int, seed::Int=123)
	Random.seed!(seed)

	i = 0
	_, factor_groups = colors_to_groups(color_passing(fg)...)
	possible_groups = collect(keys(factor_groups))
	while i < k && !isempty(possible_groups)
		idx = rand(1:length(possible_groups))
		key = possible_groups[idx]
		candidates = filter(f -> !is_unknown(f), factor_groups[key])
		if length(candidates) <= 1
			deleteat!(possible_groups, idx)
		else
			f = candidates[rand(1:length(candidates))]
			f.potentials = Dict{String, AbstractFloat}()
			i += 1
		end
	end

	i < k && @warn("Could only delete $i instead of $k potentials!")
end

"""
	similarity_score(
		node_colors_grt::Dict{RandVar, Int},
		factor_colors_grt::Dict{Factor, Int},
		node_colors_out::Dict{RandVar, Int},
		factor_colors_out::Dict{Factor, Int}
	)::Tuple{AbstractFloat, Int, Int}

Compute a similarity score for `node_colors_out` and `factor_colors_out`
with `node_colors_grt` and `factor_colors_grt` being the ground truth.
Return a tuple `(score, n, m)` where `score` is the similarity score, `n` is
the number of errors where too much grouping happened, and `m` is the number
of errors where too little grouping happened.
Assumes that each group of factors contains at least one known factor.
"""	
function similarity_score(
	node_colors_grt::Dict{RandVar, Int},
	factor_colors_grt::Dict{Factor, Int},
	node_colors_out::Dict{RandVar, Int},
	factor_colors_out::Dict{Factor, Int}
)::Tuple{AbstractFloat, Int, Int}
	diff_counter_extra = 0
	diff_counter_missing = 0

	_, f_groups_grt = colors_to_groups(node_colors_grt, factor_colors_grt)
	_, f_groups_out = colors_to_groups(node_colors_out, factor_colors_out)

	for f_group_grt in values(f_groups_grt)
		representative = filter(f -> !is_unknown(f), f_group_grt)[1]
		for f_group_out in values(f_groups_out)
			if representative in f_group_out
				f_group_grt = map(f -> name(f), f_group_grt)
				f_group_out = map(f -> name(f), f_group_out)
				overlap = intersect(f_group_grt, f_group_out)
				diff_counter_extra += length(setdiff(f_group_out, overlap))
				diff_counter_missing += length(setdiff(f_group_grt, overlap))
				break
			end
		end
	end

	diff_counter = diff_counter_extra + diff_counter_missing
	score = 1 - (diff_counter / length(keys(factor_colors_grt)))
	score < 0 && @warn "Score is negative!"
	return score, diff_counter_extra, diff_counter_missing
end

"""
	nanos_to_millis(t::AbstractFloat)::Float64

Convert nanoseconds to milliseconds.
"""
function nanos_to_millis(t::AbstractFloat)::Float64
    # Nano /1000 -> Micro /1000 -> Milli /1000 -> Second
    return t / 1000 / 1000
end