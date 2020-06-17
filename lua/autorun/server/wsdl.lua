if !game.SinglePlayer() then
	local resource_extension_types = {
		--Models
		--mdl=true,
		--vtx=true,
	
		--Sounds
		wav=true,
		mp3=true,
		ogg=true,
		aac=true,
	
		--Materials, Textures
		vmt=true,
		vtf=true,
		png=true,
	
		--fonts
		ttf=true,

		--animations
		ani=true
	}

	local dt = SysTime()

	local function msg(str,...)
		MsgN("[WSDL] ",string.format(str,...))
	end

	local function traverse(subPath,basePath,found_exts)
		local files,dirs = file.Find(subPath.."*",basePath)
		for _,f in pairs(files) do
			local ext = string.GetExtensionFromFilename(f)
			found_exts[ext] = true
		end
		for _,d in pairs(dirs) do
			traverse(subPath..d.."/",basePath, found_exts)
		end
	end

	local addons = engine.GetAddons()
	for k,_ in pairs( addons ) do
		addons[k].timeadded=nil
	end
	local download_count = 0
	local csum = util.CRC(table.ToString(addons))

	msg("Addon list checksum is %i",csum)

	local filecache
	if file.Exists("wsdl_cache.txt", "DATA") then
		filecache = util.JSONToTable(file.Read("wsdl_cache.txt","DATA"))
		if filecache.csum == csum then
			download_count = #filecache.sendaddons
			for _,id in pairs(filecache.sendaddons) do
				resource.AddWorkshop(id)
			end
			msg("Added %i addons to client download list from cache.",download_count)
			msg("Completed in %.4f seconds.",SysTime()-dt)
			return
		else
			filecache.csum = csum
			filecache.sendaddons = {}
		end
	else
		filecache = {}
		filecache.csum = csum
		filecache.sendaddons = {}
	end

	msg("Scanning %i addons...",#addons)

	for k,addon in pairs(addons) do
		if !addon.downloaded or !addon.mounted then continue end
		
		local found_exts = {}
		local should_add = false

		traverse("", addon.title, found_exts)
			
		-- if addon fails initial test but does not contain a map, check for resource files
		if not found_exts.bsp then
			if addon.models > 0 then
				should_add = true
			else
				for res_ext,_ in pairs(resource_extension_types) do
					if found_exts[res_ext] then
						should_add = true
						break
					end
				end
			end
		end
		
		if should_add then
			resource.AddWorkshop(addon.wsid)
			download_count=download_count+1
			table.insert(filecache.sendaddons, addon.wsid)
		end
	end

	msg("Added %i addons to client download list.",download_count)

	local t = SysTime()-dt
	msg("Completed in %.4f seconds. (%.4fs per addon)",t,t/#addons)

	file.Write("wsdl_cache.txt", util.TableToJSON(filecache))
	msg("Updated cache file because the server's addon list has changed.")
end