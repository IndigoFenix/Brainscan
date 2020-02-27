local usage = [====[

Brain Scanner
=========
Allows you to view information about historical figures in Legends Mode, relating to their personalities and values.
With no parameters, prints out information relating to the selected histfig.
Adding parameters allows you to get the average personalities of all units in the world.
Params available:
{-showall} - Show all values, including average traits.  (Normally only shows traits that are above or below average.)
{-race GOBLIN} - Selects all histfigs of the selected race.  Use the ID from the raws.
{-prof POET} - Selects all histfigs with the given profession.
{-syntag BLOODSUCKER} - Selects all histfigs with the given syndrome tag.
{-synclass WERECURSE} - Selects all histfigs with the given syndrome class.

]====]

local utils = require "utils"

local args = {...}
local first_arg = (args[1] or ''):gsub('^-*', '')
if first_arg == 'help' then
    print(usage)
    return
end

local vs = dfhack.gui.getCurViewscreen();
local focus = dfhack.gui.getCurFocus();

if df.viewscreen_textviewerst:is_instance(vs) then
	vs = vs.parent
end

local histfig_id = nil
local streamline = true

local tierRanges = {{min = 0, max = 9, weight = 4}, {min = 10, max = 24, weight = 20}, {min = 25, max = 39, weight = 85}, {min = 40, max = 60, weight = 780}, {min = 61, max = 75, weight = 85}, {min = 76, max = 90, weight = 20}, {min = 91, max = 100, weight = 4}}
local tierDesc = {'extremely low','very low','low','average','high','very high','extremely high'}
-- Gets what tier of trait that the given value falls into
-- 1: Lowest | 2: Very Low | 3: Low | 4: Neutral | 5: High | 6: Very High | 7: Highest
function getTraitTier(value)
  local range = 1
  local rounded = math.floor(value + 0.5)
  for index, data in ipairs(tierRanges) do
    if rounded >= data.min and rounded <= data.max then
      range = index
      break
    end
  end

  return range
end

function getRaceCasteIDs(raceStr, casteStr)
--  Takes a race name and a caste name and returns the appropriate race and caste IDs.
--  Returns a table of valid caste IDs if casteStr is omitted.
  if not raceStr then
	return -1
  end
  local race
  local raceIndex
  for i,c in ipairs(df.global.world.raws.creatures.all) do
    if c.creature_id == raceStr then
      race = c
      raceIndex = i
      break
    end
  end
  if not race then
    qerror('Invalid race: ' .. raceStr)
  end

  local casteIndex
  local caste_id_choices = {}
  if casteStr then
    for i,c in ipairs(race.caste) do
      if c.caste_id == casteStr then
        casteIndex = i
        break
      end
    end
    if not casteIndex then
      qerror('Invalid caste: ' .. casteStr)
    end
  else
    for i,c in ipairs(race.caste) do
      table.insert(caste_id_choices, i)
    end
  end

  return raceIndex, casteIndex, caste_id_choices
end







if df.viewscreen_legendsst:is_instance(vs) then
	if (vs ~= nil) and (vs.histfigs ~= nil) and (vs.sub_cursor ~= nil) then
		histfig_id = vs.histfigs[vs.sub_cursor]
	end
end

for id, name in ipairs(df.job_skill) do
	--print (id .. ': ' .. name)
end

function synTags(curse)
	local tags = {}
	local hastags = false
	for effect_index, effect in ipairs(curse.active_effects) do
		for syn_index, syndrome in ipairs(effect.syndrome) do
			for ce_index, ce in ipairs(syndrome.ce) do
				if (df.creature_interaction_effect_add_simple_flagst:is_instance(ce)) then
					hastags = true
					for tag, value in pairs(ce.tags1) do
						if (value == true) then tags[tag] = true end
					end
					for tag, value in pairs(ce.tags2) do
						if (value == true) then tags[tag] = true end
					end
				end
			end
		end
	end
	if (hastags == false) then return nil end
	return tags
end

function synClasses(curse)
	local tags = {}
	local hastags = false
	for effect_index, effect in ipairs(curse.active_effects) do
		for syn_index, syndrome in ipairs(effect.syndrome) do
			for class_index, syn_class in ipairs(syndrome.syn_class) do
				tags[syn_class.value] = true
				hastags = true
			end
		end
	end
	if (hastags == false) then return nil end
	return tags
end


--printall(histfig.info.curse.active_effects[0].syndrome[0].syn_class[0])

function printHistfig(histfig_id)
	local histfig = df.global.world.history.figures[histfig_id]
	print (dfhack.TranslateName(histfig.name))
	local unit_id = histfig.unit_id
	local i
	if (histfig.info ~= nil) then
		if (histfig.info.personality ~= nil) then
			print("Personality:")
			
			--printall (histfig.info.personality.anon_1)
			printall (histfig.info.personality.anon_1.emotions)
			for i=1, #histfig.info.personality.anon_1.dreams do
				print ('Has a dream: type ' .. (histfig.info.personality.anon_1.dreams[i-1].type))
			end
			for index, traitName in ipairs(df.personality_facet_type) do
				if (index > -1) then
					local strength = histfig.info.personality.anon_1.traits[traitName]
					local tier = getTraitTier(strength)
					if (streamline == false or tier ~= 4) then
						print (traitName .. ': ' .. tierDesc[tier] .. ' (' .. strength .. ')')
					end
				end
			end
			
			print("Values:")
			
			for i=1, #histfig.info.personality.anon_1.values do
				local value = histfig.info.personality.anon_1.values[i-1]
				print (df.value_type[value.type] .. ': ' .. value.strength)
			end
		else
			print("No personality info available")
		end
		if (histfig.info.skills ~= nil) then
			print ('Profession: ' .. df.profession[histfig.info.skills.profession])
			print ('Skills:')
			
			for i=1, #histfig.info.skills.skills do
				print (df.job_skill[histfig.info.skills.skills[i-1]] .. ': ' .. histfig.info.skills.points[i-1])
			end
		else
			print("No skill info available")
		end
		if (histfig.info.curse ~= nil) then
			syndrome = synClasses(histfig.info.curse)
			if (syndrome ~= nil) then
				print("Syndrome classes:")
				for tag in pairs(syndrome) do
					print (tag)
				end
			end
		end
		
	else
		print ('No info available')
	end
	--printall(histfig)
		--printall (df.global.world.nemesis.all[unit_id])
end

function getAverages(params)
	local allfigs = df.global.world.history.figures
	local figcount = 0
	local trait_totals = {}
	local i
	local hf
	for index, traitName in ipairs(df.personality_facet_type) do
		trait_totals[traitName] = 0
		--table.insert(trait_totals,0)
	end
	for hf=1, #allfigs do
		local histfig = allfigs[hf - 1]
		local valid = true
		if (params['race'] ~= nil and histfig.race ~= params['race']) then valid = false end
		if (params['profession'] ~= nil and (histfig.info == nil or histfig.info.skills == nil or df.profession[histfig.info.skills.profession] ~= params['profession'])) then valid = false end
		if (params['syntag'] ~= nil) then
			if (histfig.info == nil or histfig.info.curse == nil) then 
				valid = false
			else
				local syndrome = synTags(histfig.info.curse)
				if (syndrome == nil or syndrome[params['syntag']] == nil) then valid = false end
			end
		end
		if (params['synclass'] ~= nil) then
			if (histfig.info == nil or histfig.info.curse == nil) then 
				valid = false
			else
				local syndrome = synClasses(histfig.info.curse)
				if (syndrome == nil or syndrome[params['synclass']] == nil) then valid = false end
			end
		end
		if valid == true then
			--print (dfhack.TranslateName(histfig.name))
			if (histfig.info ~= nil and histfig.info.personality ~= nil) then
				--printall(histfig.info.personality.anon_1.traits)
				for index, traitName in ipairs(df.personality_facet_type) do
					if (index > -1) then
						local strength = histfig.info.personality.anon_1.traits[traitName]
						trait_totals[traitName] = trait_totals[traitName] + strength
					end
				end
				figcount = figcount + 1
			end
		end
	end
	print (figcount .. ' figures scanned')
	if (figcount > 0) then
		local trait_averages = {}
		for index, traitName in pairs(trait_totals) do
			if (index ~= 'NONE') then
				trait_averages[index] = trait_totals[index] / figcount
			end
		end
		for traitName, strength in pairs(trait_averages) do
			--local strength = trait_averages[traitName]
			local tier = getTraitTier(strength)
			if (streamline == false or tier ~= 4) then
				print (traitName .. ': ' .. tierDesc[tier] .. ' (' .. strength .. ')')
			end
		end
		--printall(trait_averages)
	end
end

--printall(df)

local args = {...}

if #args == 0 or (#args == 1 and args[1] == '-showall') then
	if (#args == 1) then streamline = false end
	if histfig_id ~= nil then
		printHistfig(histfig_id)
	end
else
	local params = {}
	for a=1, #args do
		local arg = args[a]
		if (arg == '-race') then
			local race
			local raceIndex
			local raceStr = args[a+1]
			for i,c in ipairs(df.global.world.raws.creatures.all) do
				if c.creature_id == raceStr then
					race = c
					raceIndex = i
					break
				end
			end
			if not race then
				qerror('Invalid race: ' .. raceStr)
			else
				params['race'] = raceIndex
			end
		elseif (arg == '-caste') then
			if (params['race'] ~= nil) then
			else
				qerror('No race found')
			end
		elseif (arg == '-showall') then
			streamline = false
		elseif (arg == '-prof') then
			params['profession'] = args[a+1]
		elseif (arg == '-vampire') then
			params['vampire'] = true
		elseif (arg == '-syntag') then
			params['syntag'] = args[a+1]
		elseif (arg == '-synclass') then
			params['synclass'] = args[a+1]
		elseif (arg == '-secret') then
			if (args[a+1] == '*') then
				params['secret'] = '*'
			else
				
			end
			
		end
	end
	getAverages(params)
end

	--printall(df)
