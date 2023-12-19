"""
	Query

Struct to represent a simple query.
"""
struct Query
	query_var::AbstractString
	evidence::Dict{AbstractString, Any}
	Query(q::AbstractString) = new(q, Dict())
	Query(q::AbstractString, e::Dict) = new(q, e)
end

"""
	Base.show(io::IO, q::Query)

Show the query `q` on `io`.
"""
function Base.show(io::IO, q::Query)
	y = q.query_var
	x = join([string(k, "=", v) for (k, v) in q.evidence], ",")
	print(io, isempty(x) ? "P($y)" : "P($y | $x)")
end

"""
	blog_to_queries(file::IO)::Vector{Query}

Retreive all queries from BLOG (Bayesian logic) syntax.
Assumes that all observations are given before the queries.
"""
function blog_to_queries(file::IO)::Vector{Query}
	queries = []
	open(file) do f
		obs = Dict()
		for line in eachline(f)
			line = strip(line)
			if startswith(line, "obs")
				line = replace(line, "obs" => "", ";" => "")
				var, val = strip.(split(line, "="))
				obs[var] = val
			elseif startswith(line, "query")
				line = replace(line, "query" => "", ";" => "")
				query_var = strip(line)
				push!(queries, Query(query_var, obs))
			end
		end
	end
	return queries
end

"""
	query_to_blog(q::Query, d::Dict{RandVar, String})::Vector{String}

Transform a query into BLOG syntax.
The resulting strings are stored in a vector with one entry for each
observation (evidence assignment) and one entry for the query (to allow
for sorting by obs/query afterwards if there are multiple queries
transformed into BLOG syntax).
The dictionary `d` maps the random variables to their names in the BLOG
syntax (e.g., names might change after replacing random variables by
parameterized random variables).
"""
function query_to_blog(q::Query, d::Dict{RandVar, String})::Vector{String}
	result = []
	d = Dict(name(key) => value for (key, value) in d)
	for (evidence, assignment) in q.evidence
		name = d[evidence]
		push!(result, string("obs", " ", name, " = ", assignment, ";"))
	end
	push!(result, string("query", " ", d[q.query_var], ";"))
	return result
end