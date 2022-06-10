################################################################################

function process!(self::HMM, d::Array{T, 2}, splitSw::Bool; params::HMMParams) where T <: Number

  # reset
  reset!(self)

  # feed frame
  for ι ∈ axes(d, 1)
    feed!(self, ι, d, params = params)
  end

  # backtrace
  backTrace(self)

  divider = fill(1, size(self.data, 1))
  orig = deepcopy(self.data)
  pp = StructArrays.StructArray{ScorePair}(undef, 0)

  # log
  @info "Intiate Score Pair: $(pp |> size)"

  # update model
  mdist = zeros(Float64, size(self.data))
  mcount = zeros(Float64, size(self.data))

  for ι ∈ axes(d, 1)
    self.data[self.traceback[ι]] .+= d[ι, :]
    divider[self.traceback[ι]] += 1
    pair = ScorePair(params.distance(orig[self.traceback[ι]], d[ι, :]), ι)

    mdist[self.traceback[ι]] += pair.score
    mcount[self.traceback[ι]] += 1

    push!(pp, pair)
  end

  scores = sort(pp.score, rev = true)
  ixs = map(χ -> findall(χ .== pp.score), scores)
  pp = pp[vcat(ixs...)]

  # log
  @info "Concatenated Score Pair: $(pp |> size)"

  # update / normalize models
  for ι ∈ eachindex(self.data)
    self.data[ι] /= divider[ι]
  end

  if params.verbosity
    for ε ∈ eachindex(self.data)
      @info "Print state $(ε)"
      for ι ∈ eachindex(self.data[ε])
        println(round(self.data[ε][ι]; digits = 3))
      end
    end
  end

  sortHMM!(self)

  if !splitSw
    return
  end

  max = 0.
  toSplit = 1

  for ι ∈ eachindex(mdist)
    if mcount[ι] > params.minimumFrequency
      avdist = mdist[ι] / mcount[ι]
      if avdist > max
        max = avdist
        toSplit = ι
      end
    end
  end

  half = 1 + mcount[toSplit] / 4

  extra = fill(0, size(self.data[1], 1))

  count = 1
  for ι ∈ eachindex(pp)
    if self.traceback[pp[ι].index] != toSplit
      continue
    end
    extra += d[pp[ι].index, :]
    count += 1
    if count >= half
      break
    end
  end

  @info "Count: $(count) => Expected > 1"

  extra ./= (count - 1)

  push!(self.data, extra)

  push!(self.model, fill(0, size(self.model[1], 1)))

  return

end

################################################################################