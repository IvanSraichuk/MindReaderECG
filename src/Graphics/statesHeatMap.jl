################################################################################

import CairoMakie
import DelimitedFiles

################################################################################

function plotHeatmap(inDc::Dict{String,Tuple{Array{Int64,1},Array{Array{Float64,1},1}}})

  @info "Plotting..."
  # create array to plot
  toHeat, keyString = collectState(inDc)

  # collect stats & write
  stats = stateStats(toHeat)
  DelimitedFiles.writedlm(string(outdir, "/", outimg, ".csv"), stats, ", ")

  # # add label tracks
  # for ix in 1:size(labelAr, 2)
  #   toHeat[ix, :] .= labelAr[1:size(toHeat, 2), ix]
  # end

  ################################################################################

  # # rendering
  # sc = AbstractPlotting.Scene()
  # sc = AbstractPlotting.heatmap(toHeat', show_axis = false)
  # CairoMakie.save("hm.svg", sc, pt_per_unit = 0.5)

  ################################################################################

  # plot layout
  plotFig = CairoMakie.Figure()
  heatplot = plotFig[1, 1] = CairoMakie.Axis(plotFig, title = "States Heatmap")

  # axis labels
  heatplot.xlabel = "Recording Time"
  heatplot.ylabel = "Channels"
  heatplot.yticks = 1:22

  # heatmap plot & color range
  hm = CairoMakie.heatmap!(heatplot, toHeat')
  hm.colorrange = (0, 5)

  # color bar
  cbar = plotFig[2, 1] = CairoMakie.Colorbar(plotFig, hm, label = "HMM states")
  cbar.vertical = false
  cbar.height = 10
  cbar.width = CairoMakie.Relative(2 / 3)
  cbar.ticks = 0:1:5

  ################################################################################

  CairoMakie.save(string(outdir, "/", outimg, ".svg"), plotFig, )

  ################################################################################

end

################################################################################