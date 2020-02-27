--@ module = true
--[====[
Prints out a scan of the mind of the selected unit in Legends Mode
]====]

--=======================

local utils = require "utils"

local vs = dfhack.gui.getCurViewscreen();
local focus = dfhack.gui.getCurFocus();

if df.viewscreen_textviewerst:is_instance(vs) then
	vs = vs.parent
end

local histfig_id = nil

local tierRanges = {{min = 0, max = 9, weight = 4}, {min = 10, max = 24, weight = 20}, {min = 25, max = 39, weight = 85}, {min = 40, max = 60, weight = 780}, {min = 61, max = 75, weight = 85}, {min = 76, max = 90, weight = 20}, {min = 91, max = 100, weight = 4}}
local tierDesc = {'extremely low','very low','low','average','high','very high','extremely high'}
-- Gets what tier of trait that the given value falls into
-- 1: Lowest | 2: Very Low | 3: Low | 4: Neutral | 5: High | 6: Very High | 7: Highest
function getTraitTier(value)
  local range = 1
  for index, data in ipairs(tierRanges) do
    if value >= data.min and value <= data.max then
      range = index
      break
    end
  end

  return range
end

if df.viewscreen_legendsst:is_instance(vs) then
	if (vs ~= nil) and (vs.histfigs ~= nil) and (vs.sub_cursor ~= nil) then
		histfig_id = vs.histfigs[vs.sub_cursor]
	end
end

--for id, name in ipairs(df.dream_types) do
	--print (id .. ': ' .. name)
--end

if histfig_id ~= nil then
	local histfig = df.global.world.history.figures[histfig_id]
	print (dfhack.TranslateName(histfig.name))
	local unit_id = histfig.unit_id
	--print (unit_id)
	local i
	local streamline = true
	--printall (histfig.info)
	if (histfig.info.personality ~= nil) then
		print("Personality:")
		
		--printall (histfig.info.personality.anon_1)
		printall (histfig.info.personality.anon_1.emotions)
		for i=1, #histfig.info.personality.anon_1.dreams do
			print ('Has a dream: type ' .. (histfig.info.personality.anon_1.dreams[i-1].type))
		end
		for index, traitName in ipairs(df.personality_facet_type) do
			if (index > -1) then
				local strength = histfig.info.personality.anon_1.traits[index]
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
		print("No personality")
	end
	--printall (df.global.world.nemesis.all[unit_id])
end
