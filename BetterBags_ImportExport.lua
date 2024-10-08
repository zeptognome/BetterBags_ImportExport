---@class BetterBags: AceAddon
local addon = LibStub('AceAddon-3.0'):GetAddon("BetterBags")

---@class Categories: AceModule
local categories = addon:GetModule('Categories')

---@class Localization: AceModule
local L = addon:GetModule('Localization')

---@class Config: AceModule
local config = addon:GetModule('Config')

local createCategoryColor = {r = 1, g = 1, b = 1}
local createCategoryName = ""
local categoryToCopy = ""

local importItemList = ""
local importCategoryName = ""

local exportString = ""
local errorString = ""
local exportNames = false
local categoryToExport = ""

local createConfigOptions = {
  createCategory = {
    name = L:G("Create Color Category"),
    type = "group",
    inline = true,
    args = {
      createHelp = {
        type = "description",
        name = L:G("Create a custom category with a specific color.\nPlease note these may not sort correctly."),
        order = 0,
      },
      name = {
        name = L:G("New Category Name"),
        type = "input",
        order = 1,
        get = function()
          return createCategoryName
        end,
        set = function(_, value)
          createCategoryName = value
        end,
      },
      create = {
        type = "execute",
        name = L:G("Create Category"),
        order = 2,
        disabled = function () if createCategoryName == "" then return true else return false end end,
        func = function()
          if createCategoryName == "" then return end
          local color = CreateColor(createCategoryColor.r, createCategoryColor.g, createCategoryColor.b)
          local colorName = WrapTextInColor(createCategoryName,color)
          ---@type CustomCategoryFilter
          local newcat = { name = colorName,itemList = {}, save = true}
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
          createCategoryColor.r, createCategoryColor.g, createCategoryColor.b = r, g, b
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
    }
  }
}

local importConfigOptions = {
  importCategory = {
    name = L:G("Import Category"),
    type = "group",
    inline = true,
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
          for item in string.gmatch(importItemList, "%d+") do
            local itemID = tonumber(item)
            if itemID and C_Item.GetItemInfoInstant(itemID) then
                categories:AddPermanentItemToCategory(itemID, importCategoryName)
            end
          end
          importItemList = ""
          importCategoryName = ""
        end,
      },
    }
  }
}

local exportConfigOptions = {
  exportCategory = {
    name = L:G("Export Category"),
    type = "group",
    inline = true,
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
      output = {
        name = L:G("Export"),
        type = "input",
        multiline = true,
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
}

if (config.AddPluginConfig) then
  config:AddPluginConfig("Create Color Category", createConfigOptions)
  config:AddPluginConfig("Import", importConfigOptions)
  config:AddPluginConfig("Export", exportConfigOptions)
else
  print ("BetterBags_ImportExport NOT loaded. Betterbags Plugin API Incompatible. Update to BetterBags v0.1.27-5 alpha or newer")
end