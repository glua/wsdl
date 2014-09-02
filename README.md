wsdl
====

A script that automatically adds workshop addons to the client download list.

When you run the console command "wsdl_buildmanifest", the script will scan the server's workshop addons and generate a manifest file.
Any addons with models or sounds will be added to the manifest. The next time the map changes, the addons will be added to the client download list via resource.AddWorkshop().
Any addon that contains the current map will also be added.

Note that the console command may lag the server, and will need to be run every time the addons change. The manifest is located in 'data/wsdl_manifest.txt', if you want to edit it.

The addon itself is available on the workshop: http://steamcommunity.com/sharedfiles/filedetails/?id=309020990