--Localized Lua libraries
local newRand = math.random
local tbinsert = table.insert

return function (...)
  
  local config = {...}
  
  local g = {}

  -- configuration
  g.problemSize = config[1] or 64
  g.populationSize = config[2] or 64
  g.maxGenerations = config[3] or 50
  g.selectionTournamentSize = config[4] or 3
  g.mutationRate = config[5] or 0.005
  g.crossoverRate = config[6] or 0.98

  function g.crossover(a, b)
    if newRand() > g.crossoverRate then return a end
    local cut = newRand(a:len()-1)
    return a:sub(1,cut) .. b:sub(cut+1, -1)
  end

  function g.mutation(bitstring)
    local s,sp = {}, 1
    for c in string.gmatch(bitstring, ".") do
      if newRand() < g.mutationRate then
        if c == "0" then s[sp] = "1"
        else s[sp] = "0" end
      else
        s[sp] = c
      end
      sp = sp + 1
    end

    return table.concat(s)
  end

  function g.selection(population, fitnesses)
    local pop = {}
    repeat
      local bestString
      local bestFitness = 0
      for i=1, g.selectionTournamentSize do
        local selection = newRand(#fitnesses)
        if fitnesses[selection] > bestFitness then
          bestFitness = fitnesses[selection]
          bestString = population[selection]
        end
      end
      tbinsert(pop, bestString)
    until #pop == #population
    return pop
  end

  function g.reproduce(selected)
    local pop = {}
    for i=1, #selected do
      local p1 = selected[i]
      local p2
      if (i%2)==0 then p2=selected[i-1] else p2=selected[i+1] end
      local child = g.crossover(p1, p2)
      local mutantChild = g.mutation(child)
      tbinsert(pop, mutantChild);
    end
    return pop
  end

  function g.fitness(bitstring)
    local cost = 0
    for c in string.gmatch(bitstring, ".") do
      if c == "1" then cost = cost + 1 end
    end
    return cost
  end

  function g.random_bitstring(length)
    local s = {}
    for sp = 1, length do
      if newRand() < 0.5 then s[sp] = "0"
      else s[sp] = "1" end
    end
    return table.concat(s)
  end

  function g.getBest(currentBest, population, fitnesses)
    local bestScore = currentBest==nil and 0 or g.fitness(currentBest)
    local best = currentBest
    for i=1, #fitnesses do
      local f = fitnesses[i]
      if(f > bestScore) then
        bestScore = f
        best = population[i]
      end
    end
    return best
  end

  function g.evolve()
    local population = {}
    local bestString = nil
    -- initialize the popuation random pool
    for i=1, g.populationSize do
      tbinsert(population, g.random_bitstring(g.problemSize))
    end
    -- optimize the population (fixed duration)
    for i=1, g.maxGenerations do
      -- evaluate
      local fitnesses = {}
      for i=1, #population do
        local v = population[i]
        tbinsert(fitnesses, g.fitness(v))
      end
      -- update best
      bestString = g.getBest(bestString, population, fitnesses)
      -- select
      local tmpPop = g.selection(population, fitnesses)
      -- reproduce
      population = g.reproduce(tmpPop)
      --printf(">gen %d, best cost=%d [%s]\n", i, fitness(bestString), bestString)
    end
    return bestString
  end
  
  return g

end

-- run
--printf("Genetic Algorithm on OneMax, with %s\n",_VERSION);
--math.randomseed(os.time())
--local best = evolve()
--printf("Finished!\nBest solution found had the fitness of %d [%s].\n", fitness(best), best)