local read_manifest = file.Read("wsdl_manifest.txt")

if read_manifest==nil then
	print('[WSDL] No manifest. Run "wsdl_buildmanifest" to generate the manifest.')
else
	read_manifest=util.JSONToTable(read_manifest)
	for k,v in pairs(read_manifest.general) do
		resource.AddWorkshop(v)
	end
	print("[WSDL] Added "..#read_manifest.general.." workshop addons to download list.")
	local mapaddon = read_manifest.maps[game.GetMap()]
	if mapaddon then
		print('[WSDL] Added workshop addon for map "'..game.GetMap()..'".')
	else
		print('[WSDL] No workshop addon found for map "'..game.GetMap()..'".')
	end
end

/*
	Format Info: https://github.com/garrynewman/gmad/blob/master/src/create_gmad.cpp
*/

local function freadstring(f)
	local str=""
	while true do
		local c= f:ReadByte()
		if c==0 then return str end
		str= str .. string.char(c)
	end
end

local types_content = {
	models=true,
	sound=true
}

concommand.Add("wsdl_buildmanifest",function()
	print("Building WSDL manifest...")
	local failures=0
	local manifest={general={},maps={}}

	for k,addon in pairs(engine.GetAddons()) do
		if !addon.downloaded or !addon.mounted then continue end

		local fname = addon.file
		local addon_id = addon.wsid

		print("Starting "..fname)
		local fobj = file.Open(fname,"rb","MOD")
		if !fobj then print(" - FAILURE! File does not exist! Did you try using a linked collection? It won't work!") failures=failures+1 continue end
		if fobj:Read(4)!="GMAD" then print(" - FAILURE! File ident is wrong! Seriously, what the fuck!") fobj:Close() failures=failures+1 continue end
		if fobj:ReadByte()!=3 then print(" - FAILURE! File version is wrong! This script needs updating!") fobj:Close() failures=failures+1 continue end
		fobj:ReadDouble() //Steamid (actually long long, not implemented)
		fobj:ReadDouble() //Timestamp (actually long long)
		fobj:ReadByte() //Spacer???
		freadstring(fobj) //Title
		freadstring(fobj) //Desc or addon.json
		freadstring(fobj) //Author name (not implemented)
		fobj:ReadLong() //Addon version (not implemented)
		
		local content_files=0
		local added_maps=false
		while true do
			if fobj:ReadLong()==0 then break end //File number, equals zero at end of list
			local filename = freadstring(fobj)
			fobj:ReadDouble() //File size (actually long long)
			fobj:ReadLong() //File CRC (not sure what that is, cant be too important)
			local filetype = string.match(filename,"^[^/]*")
			
			if types_content[filetype] then
				content_files = content_files+1
			elseif filetype=="maps" then
				local extension = string.match(filename,"%..*$")
				if extension==".bsp" then
					local mapname = string.sub(string.match(filename,"/.*%.bsp"),2,-5)
					print(' - Added map "'..mapname..'" to map table.')
					manifest.maps[mapname]=addon_id
					added_maps=true
				end
			end
		end
		fobj:Close()

		if content_files>0 and !added_maps then
			print(" - Added to general download list. ("..content_files.." content files)")
			table.insert(manifest.general,addon_id)
		end
	end
	print("Done!\n - Failures: "..failures.."\n - General Content Addons: "..#manifest.general.."\n - Maps: "..table.Count(manifest.maps))
	file.Write("wsdl_manifest.txt", util.TableToJSON(manifest))
	print("Manifest saved. Changes will take effect on map change/restart.")
end,nil,nil,FCVAR_SERVER_CAN_EXECUTE)