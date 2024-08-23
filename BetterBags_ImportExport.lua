---@class BetterBags: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon("BetterBags")

---@class Categories: AceModule
local categories = addon:GetModule('Categories')

---@class Localization: AceModule
local L = addon:GetModule('Localization')

---@class Config: AceModule
local config = addon:GetModule('Config')

---@class string
local importItemList = ""
---@class string
local importCategoryName = ""
---@class string
local importString = ""

---@class string
local exportString = ""
---@class string
local errorString = ""
---@class boolean
local exportNames = false
---@class boolean
local exportLabel = true
---@class string
local categoryToExport = ""

---@class string
local renameCategoryName = ""

---@func GetCreateConfigOptions
---@returns AceConfig.OptionsTable
local function GetCreateConfigOptions()

  ---@class string
  local createCategoryName = ""
  local formattedName = ""
  ---@class color
  local createCategoryColor = {r = 1, g = 1, b = 1}
  ---@class string
  local categoryToCopy = ""
  ---@class AceConfig.OptionsTable
  local options = {}

  ---@func getformattedName
  ---@param createName string
  local function setformattedName(createName)
    if not createName then return end
    local color = CreateColor(createCategoryColor.r, createCategoryColor.g, createCategoryColor.b)
    formattedName = WrapTextInColorCode(createName, color:GenerateHexColor())
  end

  options = {
    name = L:G("Create Color Category"),
    type = "group",
    inline = false,
    args = {
      createHelp = {
        hidden = false,
        type = "description",
        name = L:G("Create a custom category with a specific color.\nPlease note these may not sort correctly."),
        order = 0,
      },
      name = {
        name = L:G("New Category Name"),
        type = "input",
        order = 1,
        get = function() return createCategoryName end,
        set = function(_, value) createCategoryName = value:gsub("||", "|") end,
      },
      create = {
        type = "execute",
        name = L:G("Create Category"),
        order = 2,
        disabled = function () if createCategoryName == "" then return true else return false end end,
        func = function()
          if createCategoryName == "" then return end
          ---@type CustomCategoryFilter
          local newcat = { name = formattedName,itemList = {}, save = true}
          categories:CreateCategory(newcat)
          createCategoryName = ""
        end,
      },
      colorchoice = {
        name = L:G("Color"),
        type = "header",
        order = 3,
      },
      color = {
        type = "color",
        name = L:G("Color"),
        desc = "Choose the category color.",
        order = 4,
        get = function()
          return createCategoryColor.r, createCategoryColor.g, createCategoryColor.b
        end,
      set = function(_, r, g, b)
        createCategoryColor.r = r
        createCategoryColor.g = g
        createCategoryColor.b = b
        setformattedName(createCategoryName)
        end,
      },
      category = {
        type = "select",
        style = "dropdown",
        name = L:G("Category to copy"),
        desc = L:G("Choose a category to copy its color"),
        order = 5,
        disabled = false,
        values = function () local categoryNameList = {}
          local categorylist = categories:GetAllCategories()
          for _, k in pairs(categorylist) do
            if (string.match(k.name,"|c%x%x%x%x%x%x%x%x")) then
              categoryNameList[k.name]= k.name
            end
          end
          return categoryNameList
        end,
      get = function() return categoryToCopy end,
      set = function(_, value)
        categoryToCopy = value
        local categorycolor = string.match(categoryToCopy,"|c%x%x%x%x%x%x%x%x")
        if categorycolor then
          local color = CreateColorFromHexString (string.sub(categorycolor,3,10))
          createCategoryColor.r, createCategoryColor.g, createCategoryColor.b = color:GetRGB()
        end
      end,
      },
      preview = {
        name = L:G("Preview"),
        type = "header",
        order = 5,
      },
      display = {
        order = 6,
        type = "input",
        name = "Preview:",
        disabled = true,
        get = function() return formattedName end
      },
      output = {
        order = 7,
        type = "input",
        name = "Raw:",
        disabled = true,
        get = function() return formattedName:gsub("|", "||") end
      },

    }
}
  return options
end

---@func parseItemString
---@param importItemString string
---@return string
local function parseItemString(importItemString)
  local categoryName = string.match(importItemString, "{$w*}")
  return categoryName
end

parseItemString("")

---@func importItemstoCategory
---@param importItemString string
---@param categoryName string
local function importItemstoCategory(importItemString, categoryName)
  for item in string.gmatch(importItemString, "%d+") do
    local itemID = tonumber(item)
    if itemID and C_Item.GetItemInfoInstant(itemID) then
        categories:AddPermanentItemToCategory(itemID, categoryName)
    end
  end
end

---@func importCategories
---@param importItemString string
local function importCategories(importItemString)
  print(importItemString)
end

---@class AceConfig.OptionsTable
local singleImportOptions = {
  name = L:G("Import Category"),
  type = "group",
  order = 0,
  args = {
    createHelp = {
        type = "description",
        name = L:G("Import items into a category. Non numeric characters are ignored."),
        order = 0,
    },
    item = {
        name = L:G("Item List"),
        type = "input",
        multiline = true,
        width = "full",
        order = 1,
        get = function() return importItemList end,
        set = function(_, value) importItemList = value end,
    },
    category = {
        type = "select",
        style = "dropdown",
        name = L:G("Category"),
        desc = L:G("Choose the category to import into"),
        order = 2,
        values = function() local categoryNameList = {}
          local categorylist = categories:GetAllCategories() for _, k in pairs(categorylist) do
            categoryNameList[k.name]= k.name
          end
          return categoryNameList
        end,
        get = function() return importCategoryName end,
        set = function(_, value) importCategoryName = value end,
    },
    import = {
        type = "execute",
        name = L:G("Import to Category"),
        order = 3,
        disabled = function() if importCategoryName == "" or importItemList == "" then return true else return false end end,
        func = function()
          importItemstoCategory(importItemList,importCategoryName)
          importItemList = ""
          importCategoryName = ""
        end,
    },
  }
}

---@class AceConfig.OptionsTable
local bulkImportOptions = {
  name = L:G("Import Multiple Categories"),
  type = "group",
  order = 1,
  args = {
    exportHelp = {
      type = "description",
      name = L:G("Paste import string"),
      order = 0,
    },
    execute = {
      type = "execute",
      name = L:G("Import Categories"),
      order = 2,
      func = function()
        importCategories(importString)
      end,
    },
    input = {
      name = L:G("Import"),
      type = "input",
      multiline = 20,
      width = "full",
      order = 3,
      get = function() return importString end,
      set = function(_, value) importString = value end,
    },
  },
}

---@func exportCategory
---@param category string
---@param shouldExportNames boolean
---@return string
local function exportCategorytostring(category, shouldExportNames)
  local list = ""
  local items = categories:GetMergedCategory(category).itemList
  for itemID in pairs(items) do
    if C_Item.GetItemInfo(itemID) then
      list = list..itemID..","
      if shouldExportNames or true then
        list = list.." -- "..C_Item.GetItemNameByID(itemID).."\n"
      end
    end
  end
  print (list)
  return list
end

---@func exportAllCategories
local function exportAllCategories()
  exportString = ""
  local categorylist = categories:GetAllCategories()
  for _, k in pairs(categorylist) do
    print(#categorylist)
    exportString = "{"..k.name:gsub("|", "||").."}\n"
    exportString = exportString..exportCategorytostring(k.name, exportNames)
  end
end

---@class AceConfig.OptionsTable
local singleExportOptions = {
  name = L:G("Export Category"),
  type = "group",
  order = 0,
  args = {
    exportHelp = {
      type = "description",
      name = L:G("Select an existing category to export. Use select all and copy to export"),
      order = 0,
    },
    category = {
      type = "select",
      style = "dropdown",
      name = L:G("Category"),
      desc = L:G("Choose the category to export"),
      order = 1,
      values = function () local categoryNameList = {}
        local categorylist = categories:GetAllCategories() for _, k in pairs(categorylist) do
          categoryNameList[k.name]= k.name
        end
        return categoryNameList
      end,
      get = function() return categoryToExport end,
      set = function(_, value)
        exportString = ""
        errorString = ""
        categoryToExport = value
        if categoryToExport == "" then return end
        local items = categories:GetMergedCategory(categoryToExport).itemList
        for itemID in pairs(items) do
          if C_Item.GetItemInfo(itemID) then
            exportString = exportString..itemID..","
            if exportNames then
              local container = ContinuableContainer:Create()
              container:AddContinuable(Item:CreateFromItemID(itemID))
              container:ContinueOnLoad(function() exportString = exportString.." -- "..C_Item.GetItemNameByID(itemID).."\n" end)
            end
          else
            errorString = errorString..itemID..","
          end
        end
    end,
    },
    exportnames = {
      type = "toggle",
      width = "full",
      order = 2,
      name = L:G("Item names as comments"),
      --desc = L:G("If enabled, a search bar will appear at the top of your bags."),
      get = function()
        return exportNames
      end,
      set = function(_, value)
        exportNames = value
        exportString = ""
        errorString = ""
        if categoryToExport == "" then return end
        local items = categories:GetMergedCategory(categoryToExport).itemList
        for itemID in pairs(items) do
          if C_Item.GetItemInfo(itemID) then
            exportString = exportString..itemID..","
            if exportNames then
              local container = ContinuableContainer:Create()
              container:AddContinuable(Item:CreateFromItemID(itemID))
              container:ContinueOnLoad(function() exportString = exportString.." -- "..C_Item.GetItemNameByID(itemID).."\n" end)
            end
          else
            errorString = errorString..itemID..","
          end
        end
      end,
    },
    exportlabel = {
      type = "toggle",
      width = "full",
      order = 3,
      name = L:G("Category Name"),
      --desc = L:G("If enabled, a search bar will appear at the top of your bags."),
      get = function()
        return exportLabel
      end,
      set = function(_, value)
        exportLabel = value
        exportString = ""
        errorString = ""
        if categoryToExport == "" then return end
        if exportLabel then exportString = "{"..categoryToExport:gsub("|", "||").."}\n" end
        local items = categories:GetMergedCategory(categoryToExport).itemList
        for itemID in pairs(items) do
          if C_Item.GetItemInfo(itemID) then
            exportString = exportString..itemID..","
            if exportNames then
              local container = ContinuableContainer:Create()
              container:AddContinuable(Item:CreateFromItemID(itemID))
              container:ContinueOnLoad(function() exportString = exportString.." -- "..C_Item.GetItemNameByID(itemID).."\n" end)
            end
          else
            errorString = errorString..itemID..","
          end
        end
      end,
    },
    output = {
      name = L:G("Export"),
      type = "input",
      multiline = 20,
      width = "double",
      order = 4,
      get = function()
        return exportString
      end,
    },
    errorsection = {
      name = L:G("Unknown Items"),
      type = "header",
      order = 5,
      hidden = function() if errorString == "" then return true else return false end end,
    },
    errors = {
      name = L:G("Items with no name (probably invalid)"),
      type = "input",
      multiline = 3,
      width = "double",
      order = 6,
      hidden = function() if errorString == "" then return true else return false end end,
      get = function()
        return errorString
      end,
    },
    recheck = {
      type = "execute",
      name = L:G("Recheck Items"),
      order = 7,
      hidden = function() if errorString == "" then return true else return false end end,
      func = function()
        exportString = ""
        errorString = ""
        if categoryToExport == "" then return end
        local items = categories:GetMergedCategory(categoryToExport).itemList
        for itemID in pairs(items) do
          if C_Item.GetItemInfo(itemID) then
            exportString = exportString..itemID..","
            if exportNames then
              local container = ContinuableContainer:Create()
              container:AddContinuable(Item:CreateFromItemID(itemID))
              container:ContinueOnLoad(function() exportString = exportString.." -- "..C_Item.GetItemNameByID(itemID).."\n" end)
            end
          else
            errorString = errorString..itemID..","
          end
        end
    end,
    },
    remove = {
      type = "execute",
      name = L:G("Remove Items"),
      order = 8,
      confirm = true,
      desc = "Remove these items from all categories?",
      hidden = function() if errorString == "" then return true else return false end end,
      func = function()
        for item in string.gmatch(errorString, "%d+") do
          local itemID = tonumber(item)
          if itemID then
              categories:RemoveItemFromCategory(itemID)
          end
        end
        errorString = ""
      end,
    },
  }
}

---@class AceConfig.OptionsTable
local bulkExportOptions = {
    name = L:G("Export All Categories"),
    type = "group",
    order = 1,
    args = {
      exportHelp = {
        type = "description",
        name = L:G("Use select all and copy to export"),
        order = 0,
      },
      exportnames = {
        type = "toggle",
        width = "full",
        order = 1,
        name = L:G("Item names as comments"),
        get = function()
          return exportNames
        end,
        set = function(_, value)
          exportNames = value
          exportAllCategories()
        end,
      },
      export = {
        type = "execute",
        name = L:G("Export Categories"),
        order = 2,
        func = function()
          exportAllCategories()
        end,
      },
      output = {
        name = L:G("Export"),
        type = "input",
        multiline = 20,
        width = "full",
        order = 3,
        get = function()
          return exportString
        end,
      },
    },
}

---@class AceConfig.OptionsTable
local renameConfigOptions = {
  name = L:G("Rename Category"),
  type = "group",
  order = 4,
  args = {
    renameHelp = {
        type = "description",
        name = L:G("Rename a category. Settings will be preserved."),
        order = 0,
    },
    category = {
        type = "select",
        style = "dropdown",
        name = L:G("Category"),
        desc = L:G("Choose the category to rename"),
        order = 2,
        values = function() local categoryNameList = {}
          local categorylist = categories:GetAllCategories() for _, k in pairs(categorylist) do
            categoryNameList[k.name]= k.name
          end
          return categoryNameList
        end,
        get = function() return renameCategoryName end,
        set = function(_, value) renameCategoryName = value end,
    },
    name = {
      name = L:G("New Category Name"),
      type = "input",
      order = 3,
      get = function()
        return createCategoryName
      end,
      set = function(_, value)
        createCategoryName = value
      end,
    },
    rename = {
        type = "execute",
        name = L:G("Rename Category"),
        order = 3,
        disabled = function() if renameCategoryName == "" or createCategoryName == "" then return true else return false end end,
        func = function()
          importItemstoCategory(importItemList,renameCategoryName)
          importItemList = ""
          importCategoryName = ""
        end,
    },
  }
}

---@class AceConfig.OptionsTable
local importExportConfigOptions = {
  header = {
    type = "description",
    order = 1,
    name = "BetterBags_ImportExport features several utility functions to manage custom caregories",
  },
  splash = {
    order = 0,
    type = "header",
    name = "BetterBags_ImportExport",
  },
  create = GetCreateConfigOptions(),
  import = {
    inline = false,
    type = "group",
    name = "Import",
    childGroups = "tab",
    order = 2,
    args = {
      single = singleImportOptions,
      bulk = bulkImportOptions
    }
  },
  export = {
    inline = false,
    type = "group",
    name = "Export",
    childGroups = "tab",
    order = 3,
    args = {
      single = singleExportOptions,
      bulk = bulkExportOptions
    }
  },
  rename = renameConfigOptions,
}


if (config.AddPluginConfig) then
  config:AddPluginConfig("Import Export Utils", importExportConfigOptions)
else
  print ("BetterBags_ImportExport NOT loaded. Betterbags Plugin API Incompatible.")
end