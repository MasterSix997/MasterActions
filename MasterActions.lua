require("lib/MasterActions/translations")

data = require("lib/MasterActions/data_management")
local ui = require("lib/MasterActions/user_interface")

data.LoadSettings()
TranslationUtils.SetupLanguage(data.settings.language)

ui.create_interface()