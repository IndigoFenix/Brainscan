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
{-cursetag BLOODSUCKER} - Selects all histfigs with the given syndrome tag.
{-curseclass WERECURSE} - Selects all histfigs with the given syndrome class.
{-secret} - Selects all histfigs that have a secret interaction.
{-book} - Selects all histfigs that have written at least one book.
{-hf TYPE NUMBER} - Selects all histfigs with at least the NUMBER relationships of a particular TYPE.
	hf types are deity,spouse,former_spouse,deceased_spouse,child,lover,mother,father,parent,master,former_master,prisoner,imprisoner,apprentice,former_apprentice

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
local hfLinkType = {'deity','spouse','former_spouse','deceased_spouse','child','lover','mother','father','parent','master','former_master','prisoner','imprisoner','apprentice','former_apprentice'}
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
	if (vs ~= nil) and (vs.histfigs_filtered ~= nil) and (vs.sub_cursor ~= nil) then
		histfig_id = vs.histfigs[vs.histfigs_filtered[vs.sub_cursor]]
	end
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

function secretClasses(histfig)
	local tags = {}
	local hastags = false
	if (histfig.info == nil or histfig.info.secret == nil) then return nil end
	for int_index, interaction in ipairs(histfig.info.secret.interactions) do
		for effect_index, effect in ipairs(interaction.effects) do
			for syn_index, syndrome in ipairs(effect.syndrome) do
				if (syn_class ~= nil) then
					tags[syn_class.value] = true
				end
				hastags = true
			end
		end
	end
	if (hastags == false) then return nil end
	return tags
end

function getHfLinkType(hf)
	for index, linktype in ipairs(hfLinkType) do
		if (df['histfig_hf_link_' .. linktype .. 'st'] ~= nil and df['histfig_hf_link_' .. linktype .. 'st']:is_instance(hf)) then return linktype end
	end
	print (hf)
	return nil
end

function hasPosition(histfig)
	if (histfig.entity_links == nil) then return nil end
	for index, link in ipairs(histfig.entity_links) do
		if (df['histfig_entity_link_former_positionst']:is_instance(link) or df['histfig_entity_link_positionst']:is_instance(link) ) then return true end
	end
	return nil
end

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
				print("Curse classes:")
				for tag in pairs(syndrome) do
					print (tag)
				end
			end
		end
		
		local secret_classes = secretClasses(histfig)
		if (secret_classes ~= nil) then
			print("Secret classes:")
			for tag in pairs(secret_classes) do
				print (tag)
			end
		end
		
		
		if (histfig.info.kills ~= nil) then
		end
	else
		print ('No info available')
	end
	if (histfig.histfig_links ~= nil) then
		for index,link in ipairs(histfig.histfig_links) do
			local linktype = getHfLinkType(link)
			--print ('Link type: ' .. getHfLinkType(link))
		end
	end
	
		--printall (df.global.world.nemesis.all[unit_id])
end

function getAverages(params)
	local allfigs = df.global.world.history.figures
	local figcount = 0
	local trait_totals = {}
	local value_totals = {}
	local i
	local hf
	for index, traitName in ipairs(df.personality_facet_type) do
		trait_totals[traitName] = 0
		--table.insert(trait_totals,0)
	end
	
	if (params['battle_leader'] ~= nil) then
		allfigs = {}
		local figlist = {}
		local i = 0
		for eci, ec in pairs(df.global.world.history.event_collections.all) do
			if (df.history_event_collection_battlest:is_instance(ec)) then
				for hf1,hfid in ipairs(ec.attacker_hf) do
					if (figlist[hfid] == nil) then
						fig = df.global.world.history.figures[hfid]
						allfigs[i] = fig
						figlist[hfid] = fig
						i = i+1
						break
					end
					--table.insert(allfigs,fig)
				end
			end
		end
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
		if (params['hf'] ~= nil) then
			local hf_count = tonumber(params['hf_count'])
			local counted = 0
			if hf_count == nil or type(hf_count) ~= "number" then hf_count = 1 end
			if (histfig.histfig_links ~= nil) then
				for index,link in ipairs(histfig.histfig_links) do
					local linktype = getHfLinkType(link)
					if (linktype == params['hf']) then counted = counted + 1 end
					if counted >= hf_count then break end
				end
			end
			if counted < hf_count then valid = false end
		end
		if (params['secret'] ~= nil and secretClasses(histfig) == nil) then valid = false end
		if (params['book'] ~= nil and (histfig.info == nil or histfig.info.books == nil)) then valid = false end
		
		if (params['position'] ~= nil and (hasPosition(histfig) == nil)) then valid = false end
		
		if valid == true then
			if (histfig.info ~= nil) then
				if (histfig.info.personality ~= nil) then
					for index, traitName in ipairs(df.personality_facet_type) do
						if (index > -1) then
							local strength = histfig.info.personality.anon_1.traits[traitName]
							trait_totals[traitName] = trait_totals[traitName] + strength
						end
					end
					for i=1, #histfig.info.personality.anon_1.values do
						local value = histfig.info.personality.anon_1.values[i-1]
						local value_type = df.value_type[value.type]
						if value_totals[value_type] == nil then value_totals[value_type] = 0 end
						value_totals[value_type] = value_totals[value_type] + value.strength
					end
					figcount = figcount + 1
				end
			end
		end
		
	end
	print (figcount .. ' figures scanned')
	if (figcount > 0) then
		local trait_averages = {}
		local value_averages = {}
		for index, traitName in pairs(trait_totals) do
			if (index ~= 'NONE') then
				trait_averages[index] = trait_totals[index] / figcount
			end
		end
		for index, traitName in pairs(value_totals) do
			value_averages[index] = value_totals[index] / figcount
		end
		local has_outlier = false
		for traitName, strength in pairs(trait_averages) do
			--local strength = trait_averages[traitName]
			local tier = getTraitTier(strength)
			if (streamline == false or tier ~= 4) then
				print (traitName .. ': ' .. tierDesc[tier] .. ' (' .. strength .. ')')
				has_outlier = true
			end
		end
		for valueName, strength in pairs(value_averages) do
			--local strength = trait_averages[traitName]
			local tier = getTraitTier(strength + 50)
			if (streamline == false or tier ~= 4) then
				print (valueName .. ': ' .. tierDesc[tier] .. ' (' .. strength .. ')')
				has_outlier = true
			end
		end
		if (has_outlier == false) then
			print('No statistically significant trends. Use -showall to view all averages.')
		end
		--printall(trait_averages)
	end
end


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
		elseif (arg == '-cursetag') then
			params['syntag'] = args[a+1]
		elseif (arg == '-curseclass') then
			params['synclass'] = args[a+1]
		elseif (arg == '-secret') then
			params['secret'] = true
		elseif (arg == '-hf') then
			params['hf'] = args[a+1]
			params['hf_count'] = args[a+2]
		elseif (arg == '-book') then
			params['book'] = true
		elseif (arg == '-position') then
			params['position'] = true
		elseif (arg == '-battle_leader') then
			params['battle_leader'] = true
		elseif (arg == '-secret') then
			if (args[a+1] == '*') then
				params['secret'] = '*'
			else
				
			end
		end
	end
	getAverages(params)
end
