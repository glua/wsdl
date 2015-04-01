concommand.Add("wsdl_buildmanifest",function()
	print("The command is deprecated. WSDL no longer needs to build a manifest file. Everything should just work.")
end,nil,nil,FCVAR_SERVER_CAN_EXECUTE)

local extension_types = {
	//Models
	mdl=true,vtx=true,

	//Materials, Textures
	vmt=false,vtf=false,
	png=false,

	//Text
	txt=false,

	//Code
	lua=false,

	//AI
	ain=false,nav=false,

	//Wallpapers?
	jpg=false,jpeg=false
}

if !game.SinglePlayer() then
	local dt = SysTime()

	local function msg(str,...)
		MsgN("[WSDL] ",string.format(str,...))
	end

	local function traverse(subPath,basePath)
		local files,dirs = file.Find(subPath.."*",basePath)
		for _,f in pairs(files) do
			local ext = string.GetExtensionFromFilename(f)

			if ext=="bsp" then
				if string.StripExtension(f) == game.GetMap() then
					return true
				end
			elseif extension_types[ext]!=nil then
				if extension_types[ext] then
					return true
				end
			else
				msg("Unknown filetype: %s",f)
			end
		end
		for _,d in pairs(dirs) do
			if traverse(subPath..d.."/",basePath) then return true end
		end
	end

	local addons = engine.GetAddons()

	msg("Scanning %i addons...",#addons)

	local download_count = 0

	for k,addon in pairs(engine.GetAddons()) do
		if !addon.downloaded or !addon.mounted then continue end
		if traverse("",addon.title) then
			resource.AddWorkshop(addon.wsid)
			download_count=download_count+1
		end
	end

	msg("Added %i addons to client download list.",download_count)

	local t = SysTime()-dt
	msg("Completed in %.4f seconds. (%.4fs per addon)",t,t/#addons)
end