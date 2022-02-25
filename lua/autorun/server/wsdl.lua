if !game.SinglePlayer() then
	local resource_extension_types = {
		--Models (handled by addon.models)
	
		--Sounds
		"wav",
		"mp3",
		"ogg",
		"aac",
	
		--Materials, Textures
		"vmt",
		"vtf",
		"png",
		"jpg",
	
		--fonts
		"ttf",

		--animations
		"ani",

		--particles
		"pcf"
	}

	local function msg(str,...)
		MsgN("[WSDL] ",string.format(str,...))
	end

	local function traverse(subPath,basePath,found_exts)
		local files,dirs = file.Find(subPath.."*",basePath)
		if files then
			for _,f in ipairs(files) do
				local ext = string.GetExtensionFromFilename(f)
				found_exts[ext] = true
			end
		else
			msg("Error! could not read files in subfolder %s of addon %s   Addon is corrupted or uses a game unsupported special character in a folder/file name.",subPath,basePath)
		end
		if dirs then
			for _,d in ipairs(dirs) do
				traverse(subPath..d.."/",basePath, found_exts)
			end
		else
			msg("Error! could not read directories in subfolder %s of addon %s   Addon is corrupted or uses a game unsupported special character in a folder/file name.",subPath,basePath)
		end
	end

	local dt = SysTime()

	local addons = engine.GetAddons()
	for k,_ in ipairs( addons ) do
		addons[k].timeadded=nil
	end
	local csum = util.SHA256(table.ToString(resource_extension_types) .. table.ToString(addons))
	msg("Addon list checksum is %s",csum)

	local download_count = 0
	local filecache
	if file.Exists("wsdl_cache.txt", "DATA") then
		filecache = util.JSONToTable(file.Read("wsdl_cache.txt","DATA"))
		if filecache.csum == csum then
			download_count = #filecache.sendaddons
			for _,id in ipairs(filecache.sendaddons) do
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

	for _,addon in ipairs(addons) do
		if !addon.downloaded or !addon.mounted then continue end
		
		local should_add = false
		local found_exts = {}

		traverse("", addon.title, found_exts)
			
		-- if addon fails initial test but does not contain a map, check for resource files
		if not found_exts.bsp then
			if addon.models > 0 then
				should_add = true
			else
				for _,res_ext in ipairs(resource_extension_types) do
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