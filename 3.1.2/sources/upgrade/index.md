## Overview

If you are upgrading `oxd-server` to the latest version, we have included auto-migration functionality to easily transfer your data files. `oxd-server` now uses configurable data storage (`h2`, `redis`, etc.) instead of JSON files.   

## Legacy Compatibility
Before moving forward with an upgrade to oxd 3.1.2, review the following legacy compatibility notes:

- UMA 2.0: Supported in oxd 3.1.2 and Gluu Server 3.1.2      
- UMA 1.0.1: **Not** supported in oxd 3.1.2 or Gluu Server 3.1.2    
- OpenID Connect: Supported in all versions of oxd and Gluu Server      
- Pricing: If you upgrade existing oxd installations to oxd 3.1.2, the new per application billing model described above will take effect. This could have an impact on your monthly bill     

## OpenID Connect 
Follow these simple steps to migrate your JSON files:

- Open `oxd-conf.json` 
- Modify `migration_source_folder_path` to point to the folder or directory that contains the JSON files

!!! Note: 
    If you are using Windows OS don't forget to include the escape path separator (e.g. `C:\\OXD_OLD\\oxd-server\\conf`)

- Restart `oxd-server` to import the files
- Data migration will only happen once and will not initiate for subsequent oxd-server restarts  

## UMA 
Auto-migration between UMA 1.0.1 and UMA 2.0 is not supported because of major changes between specifications. To view the UMA 2.0 specifications follow this [link](https://docs.kantarainitiative.org/uma/ed/uma-core-2.0-01.html).
 