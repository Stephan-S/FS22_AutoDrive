


ADEditorGUI = {
	translationPrefix = "gui_ad_editor_",
	CATEGORY = "autoDrive",

}
local ADEditorGUI_mt = Class(ADEditorGUI)
ADEditorGUI.categoriesXmlFile = "gui/courseEditor.xml"
ADEditorGUI.brushesByTabName = {}
function ADEditorGUI.new(customMt)
	local self = setmetatable({}, customMt or ADEditorGUI_mt)
	self.graphWrapper = ADEditorGraphWrapper.new(ADGraphManager)
	self.lastPosition = {}

	return self
end

function ADEditorGUI:load()
	self:loadCategoriesFromXML()
end

function ADEditorGUI:draw(pos)
	self.graphWrapper:draw(pos)
end

--- Adds the auto drive category into the build menu.
function ADEditorGUI:loadCategoriesFromXML()
	local filePath = Utils.getFilename(ADEditorGUI.categoriesXmlFile,AutoDrive.directory)
	local xmlFile = XMLFile.load("adCourseEditorXML", filePath)
	local defaultIconFilename = xmlFile:getString("Categories#defaultIconFilename")
	if defaultIconFilename then 
		defaultIconFilename = Utils.getFilename(defaultIconFilename, AutoDrive.directory)
	end
	local defaultRefSize = xmlFile:getVector("Categories#refSize", {
		1024,
		1024
	}, 2)

	xmlFile:iterate("Categories.Category", function (_, key)
		local categoryName = xmlFile:getString(key .. "#name")
		local title = g_i18n:getText( string.format("%stitle", ADEditorGUI.translationPrefix))
		local iconFilename = xmlFile:getString(key .. "#iconFilename")
		if iconFilename then 
			iconFilename = Utils.getFilename(iconFilename, AutoDrive.directory)
		else 
			iconFilename = defaultIconFilename
		end
		local refSize = xmlFile:getVector(key .. "#refSize", defaultRefSize, 2)
		local iconUVs = GuiUtils.getUVs(xmlFile:getString(key .. "#iconUVs", "0 0 1 1"), refSize)

		g_storeManager:addConstructionCategory(categoryName, title, iconFilename, iconUVs, "")

		xmlFile:iterate(key .. ".Tab", function (_, tKey)
			local tabName = xmlFile:getString(tKey .. "#name")
			local tabTitle = g_i18n:getText( string.format("%s%s_title", ADEditorGUI.translationPrefix, tabName))
			local tabIconFilename = xmlFile:getString(tKey .. "#iconFilename")
			if tabIconFilename then 
				tabIconFilename = Utils.getFilename(tabIconFilename, AutoDrive.directory)
			else 
				tabIconFilename = defaultIconFilename
			end
			local tabRefSize = xmlFile:getVector(tKey .. "#refSize", defaultRefSize, 2)
			local tabIconUVs = GuiUtils.getUVs(xmlFile:getString(tKey .. "#iconUVs", "0 0 1 1"), tabRefSize)

			g_storeManager:addConstructionTab(categoryName, tabName, tabTitle, tabIconFilename, tabIconUVs, "")
			ADEditorGUI.brushesByTabName[tabName:upper()] = {}
			xmlFile:iterate(tKey .. ".Brush", function (_, bKey)
				local brushName = xmlFile:getString(bKey .. "#name")
				local brushTitle = g_i18n:getText( string.format("%s%s_%s_title", ADEditorGUI.translationPrefix, tabName, brushName))
				local brushClass  = xmlFile:getString(bKey .. "#class")
				local brushIconFilename = xmlFile:getString(bKey .. "#iconFilename")
				if brushIconFilename then 
					brushIconFilename = Utils.getFilename(brushIconFilename, AutoDrive.directory)
				else 
					brushIconFilename = defaultIconFilename
				end
				local brushRefSize = xmlFile:getVector(bKey .. "#refSize", defaultRefSize, 2)
				local brushIconUVs = GuiUtils.getUVs(xmlFile:getString(bKey .. "#iconUVs", "0 0 1 1"), brushRefSize)
				local brushData = {
					name = brushName,
					translation = string.format("%s%s_%s_", ADEditorGUI.translationPrefix, tabName, brushName),
					title = brushTitle,
					className = brushClass,
					iconFilename = brushIconFilename,
					iconUvs = brushIconUVs
				}
				table.insert(ADEditorGUI.brushesByTabName[tabName:upper()], brushData)
			end)
		end)
	end)
	xmlFile:delete()
end
g_adEditor = ADEditorGUI.new()
--- Adds all auto drive brushes.
local function buildTerrainSculptBrushes(self, superFunc,numItems)

	numItems = superFunc(self,numItems)
	local category = g_storeManager:getConstructionCategoryByName(ADEditorGUI.CATEGORY)
	local categoryIx = category.index

	for _, tabData in ipairs(category.tabs) do 
		local tabName = tabData.name
		local ix = g_storeManager:getConstructionTabByName(tabName, ADEditorGUI.CATEGORY).index
		local tab = self.items[categoryIx][ix]
		for i, brushData in ipairs(ADEditorGUI.brushesByTabName[tabName]) do 
			numItems = numItems + 1
			table.insert(tab, {
				price = 0,
				imageFilename = brushData.iconFilename,
				imageUvs = brushData.iconUvs,
				name = brushData.title,
				brushClass =  AutoDrive.getClassObject(brushData.className),
				brushParameters = {
					g_adEditor.graphWrapper,
					self.camera,
					brushData.translation
				},
				uniqueIndex = numItems
			})
		end
	end
	return numItems 
end

ConstructionScreen.buildTerrainSculptBrushes = Utils.overwrittenFunction(ConstructionScreen.buildTerrainSculptBrushes, buildTerrainSculptBrushes)

--- Draws the ad network, if the category is selected.
local function draw(self)
	--- Ad category selected
	if self.currentCategory and  self.currentCategory == g_storeManager:getConstructionCategoryByName(ADEditorGUI.CATEGORY).index then 
			--- Current mouse position.
		local x, y, z = self.cursor:getPosition()
		if x == nil then
			return
		end
		g_adEditor:draw({x, y, z})
	end
end
ConstructionScreen.draw = Utils.appendedFunction(ConstructionScreen.draw, draw)

--- Overrides the destruct button, while ad category is active. 
--- This enables wayPoint deletion with the destruct button.
local function setSelectedCategory(self, superFunc, ix, ...)
	if self.currentCategory == ix then
		return
	end
	local categoryIx = g_storeManager:getConstructionCategoryByName(ADEditorGUI.CATEGORY).index
	if categoryIx == ix then 
		self.defaultDestructText = self.buttonDestruct.text
		self.destructBrush = ADBrushDelete.new(nil, self.cursor)
		self.destructBrush:setParameters(
			g_adEditor.graphWrapper,
			self.camera,
			string.format("%sdelete_", ADEditorGUI.translationPrefix))
		self.buttonDestruct:setText(g_i18n:getText(string.format("%sdelete_title", ADEditorGUI.translationPrefix)))
	else
		if self.defaultDestructText then
			local class = g_constructionBrushTypeManager:getClassObjectByTypeName("destruct")
			self.destructBrush = class.new(nil, self.cursor)
			self.buttonDestruct:setText(self.defaultDestructText)
		end
	end

	superFunc(self, ix, ...)

	local numTabsForCategory = 0
	if self.currentCategory ~= nil then
		numTabsForCategory = #self.items[self.currentCategory]
	end
	for t, button in ipairs(self.tabsBox.elements) do
		if t <= numTabsForCategory then
			--- Makes sure the icon are updated correctly.
			local tab = self.categories[self.currentCategory].tabs[t]
			GuiOverlay.deleteOverlay(button.icon)
			button:setImageFilename(nil, tab.iconFilename)
			button:setImageUVs(nil, tab.iconUVs)
		end
	end

end
ConstructionScreen.setSelectedCategory = Utils.overwrittenFunction(ConstructionScreen.setSelectedCategory, setSelectedCategory)

local function setBrush(self, superFunc, brush, ...)
	if brush == self.brush then
		return
	end
	local lastBrush = self.brush
	superFunc(self, brush, ...)

	if self.brush and lastBrush and self.brush:isa(ADBrush) and lastBrush:isa(ADBrush) then 
		if self.brush.copyState then 
			self.brush:copyState(lastBrush)
		end
	end
end

ConstructionScreen.setBrush = Utils.overwrittenFunction( ConstructionScreen.setBrush, setBrush)
