@isdefined(FactorGraph)           || include(string(@__DIR__, "/factor_graph.jl"))
@isdefined(ParfactorGraph)        || include(string(@__DIR__, "/parfactor_graph.jl"))
@isdefined(color_passing)         || include(string(@__DIR__, "/color_passing.jl"))
@isdefined(unknown_color_passing) || include(string(@__DIR__, "/color_passing_unknown_f.jl"))
@isdefined(groups_to_pfg)         || include(string(@__DIR__, "/fg_to_pfg.jl"))
@isdefined(model_to_blog)         || include(string(@__DIR__, "/blog_parser.jl"))

function run_simple_example()
	a = DiscreteRV("A")
	b = DiscreteRV("B")
	c = DiscreteRV("C")

	p1 = [
		([true,  true],  1),
		([true,  false], 2),
		([false, true],  3),
		([false, false], 4)
	]
	f1 = DiscreteFactor("f1", [a, b], p1)
	f2 = DiscreteFactor("f2", [c, b], []) # Potentials unknown for f2

	fg = FactorGraph()
	add_rv!(fg, a)
	add_rv!(fg, b)
	add_rv!(fg, c)
	add_factor!(fg, f1)
	add_factor!(fg, f2)
	add_edge!(fg, a, f1)
	add_edge!(fg, b, f1)
	add_edge!(fg, b, f2)
	add_edge!(fg, c, f2)

	node_colors, factor_colors = unknown_color_passing(fg, color_passing)
	pfg1, _ = groups_to_pfg(fg, node_colors, factor_colors)
	model_to_blog(pfg1)
end

@info "==> Running simple example..."
run_simple_example()