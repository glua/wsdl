local resource_extension_types = {
	--Models
	mdl=true,
	vtx=true,

	--Sounds
	wav=true,
	mp3=true,
	ogg=true,

	--Materials, Textures
	vmt=true,
	vtf=true,
	png=true
}

if !game.SinglePlayer() then
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

	msg("Scanning %i addons...",#addons)

	local download_count = 0

	for k,addon in pairs(engine.GetAddons()) do
		if !addon.downloaded or !addon.mounted then continue end
		
		local found_exts = {}
		local should_add = false
		traverse("", addon.title, found_exts)
		
		-- if addon fails initial test but does not contain a map, check for resource files
		if not found_exts.bsp then
			for res_ext,_ in pairs(resource_extension_types) do
				if found_exts[res_ext] then
					should_add = true
					break
				end
			end
		end
		
		if should_add then
			resource.AddWorkshop(addon.wsid)
			download_count=download_count+1
		end
	end

	msg("Added %i addons to client download list.",download_count)

	local t = SysTime()-dt
	msg("Completed in %.4f seconds. (%.4fs per addon)",t,t/#addons)
end