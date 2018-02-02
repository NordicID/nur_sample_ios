
The project can be built for different targets/customers. In order to do that the
correct customer specific files must be taken into use. To do that simply execute
in this directory:

% ./SetupTarget.sh Targets/<target-file>.zip

where <target-file>.zip is the zip file for that target/customer.

As an example:

% ./SetupTarget.sh Targets/NordicId-files.zip

would set up the project to use the default Nordic ID files. Currently the target
specific files contain the Info.plist, theme file, EULA and the target specific assets (icons).

After extracting make sure to clean the project and then rebuild to get rid of any old
remnanants of the previous target.


To create a new zip file or update it when there are changes, do:

% zip -r Targets/<target>.zip Info.plist Source/EULA/EULA.txt Source/MetaData.plist Source/Theme/Theme.m Source/TargetAssets.xcassets Quick\ Guide/
