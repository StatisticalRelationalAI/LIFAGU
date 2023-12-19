library(ggplot2)
library(dplyr)
library(patchwork)
library(stringr)
library(tikzDevice)

results = read.csv(file = "results-prepared.csv", sep=",", dec=".")
stats = read.csv(file = "_stats-prepared.csv", sep=",", dec=".")

stats["engine"][stats["engine"] == "fove.LiftedVarElim"] = "Lifted Variable Elimination"
stats["engine"][stats["engine"] == "ve.VarElimEngine"] = "Variable Elimination"
stats = rename(stats, "Algorithm" = "engine")

tikz('plot-eval.tex', standAlone = FALSE, height = 2.5)

p1 <- ggplot(results, aes(x=d, y=mean_kl_div)) +
  geom_line(col=rgb(140,69,152, maxColorValue=255)) +
  geom_ribbon(
    aes(
      y = mean_kl_div,
      ymin = mean_kl_div - std,
      ymax = mean_kl_div + std,
    ),
    fill = rgb(140,69,152, maxColorValue=255),
    alpha = 0.15,
    colour = NA
  ) +
  xlab("$d$") +
  ylab("KL divergence") +
  theme_classic() +
  theme(
    axis.line.x = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
    axis.line.y = element_line(arrow = grid::arrow(length = unit(0.1, "cm")))
  ) +
  guides(fill = "none", color = "none")

p2 <- ggplot(stats, aes(x=d, y=mean_time, group=Algorithm, color=Algorithm)) +
  geom_line(aes(group=Algorithm, linetype=Algorithm, color=Algorithm)) +
  geom_ribbon(
    aes(
      y = mean_time,
      ymin = mean_time - std,
      ymax = mean_time + std,
      fill = Algorithm
    ),
    alpha = 0.2,
    colour = NA
  ) +
  xlab("$d$") +
  ylab("time (ms)") +
  theme_classic() +
  theme(
    axis.line.x = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
    axis.line.y = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
    legend.position = c(0.349, 0.9),
    legend.title = element_blank()
  ) + scale_fill_manual(
    values=c(
      rgb(50,113,173, maxColorValue=255),
      rgb(70,165,69, maxColorValue=255)
    )
  ) + scale_color_manual(
    values=c(
      rgb(50,113,173, maxColorValue=255),
      rgb(70,165,69, maxColorValue=255)
    )
  ) +
  guides(fill = "none")

p1 + p2 + plot_layout(ncol = 2, nrow = 1)

dev.off()
