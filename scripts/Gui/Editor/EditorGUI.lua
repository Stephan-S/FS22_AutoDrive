


ADEditorGUI = {
	--- Table to work on, similar to vehicle.ad
	ad = {
		distances = {
			closest = {
				wayPoint = -1,
				distance = 0,

			},
			closestNotReverse = {
				wayPoint = -1,
				distance = 0
			}
		},
		stateModule = {
			isActive = function ()
				return true
			end,
			getSelectedNeighbourPoint = function ()
				return nil
			end			
		},
		lastDrawPosition = {
			x = 0,
			z = 0
		}
	},	
	translationPrefix = "gui_ad_editor_"
}
local ADEditorGUI_mt = Class(ADEditorGUI)
ADEditorGUI.categoriesXmlFile = "gui/courseEditorCategories.xml"
function ADEditorGUI.new(customMt)
	local self = setmetatable({}, customMt or ADEditorGUI_mt)
	self:loadCategoriesFromXML()
	return self
end

--- Adds the auto drive category into the build menu.
function ADEditorGUI:loadCategoriesFromXML()
	local filePath = Utils.getFilename(ADEditorGUI.categoriesXmlFile,AutoDrive.directory)
	local constructionXMLFile = XMLFile.load("adConstructionXML", filePath)
	local defaultIconFilename = constructionXMLFile:getString("constructionCategories#defaultIconFilename")
	if defaultIconFilename then 
		defaultIconFilename = Utils.getFilename(defaultIconFilename, AutoDrive.directory)
	end
	local defaultRefSize = constructionXMLFile:getVector("constructionCategories#refSize", {
		1024,
		1024
	}, 2)

	constructionXMLFile:iterate("constructionCategories.category", function (_, key)
		local categoryName = constructionXMLFile:getString(key .. "#name")
		local title = g_i18n:convertText(constructionXMLFile:getString(key .. "#title"), AutoDrive.currentModName)
		local iconFilename = constructionXMLFile:getString(key .. "#iconFilename")
		if iconFilename then 
			iconFilename = Utils.getFilename(iconFilename, AutoDrive.directory)
		else 
			iconFilename = defaultIconFilename
		end
		local refSize = constructionXMLFile:getVector(key .. "#refSize", defaultRefSize, 2)
		local iconUVs = GuiUtils.getUVs(constructionXMLFile:getString(key .. "#iconUVs", "0 0 1 1"), refSize)

		g_storeManager:addConstructionCategory(categoryName, title, iconFilename, iconUVs, "")
		constructionXMLFile:iterate(key .. ".tab", function (_, tKey)
			local tabName = constructionXMLFile:getString(tKey .. "#name")
			local tabTitle = g_i18n:convertText(constructionXMLFile:getString(tKey .. "#title"), AutoDrive.currentModName)
			local tabIconFilename = constructionXMLFile:getString(tKey .. "#iconFilename")
			if tabIconFilename then 
				tabIconFilename = Utils.getFilename(tabIconFilename, AutoDrive.directory)
			else 
				tabIconFilename = defaultIconFilename
			end
			local tabRefSize = constructionXMLFile:getVector(tKey .. "#refSize", defaultRefSize, 2)
			local tabIconUVs = GuiUtils.getUVs(constructionXMLFile:getString(tKey .. "#iconUVs", "0 0 1 1"), tabRefSize)

			g_storeManager:addConstructionTab(categoryName, tabName, tabTitle, tabIconFilename, tabIconUVs, "")
		end)
	end)
	constructionXMLFile:delete()
end

--- Adds all auto drive brushes.
function ADEditorGUI:buildTerrainSculptBrushes(superFunc,numItems)

	numItems = superFunc(self,numItems)
	local categoryIx = g_storeManager:getConstructionCategoryByName("autoDrive").index
	local firstTabIx = g_storeManager:getConstructionTabByName("basic", "autoDrive").index
	local firstTab = self.items[categoryIx][firstTabIx]
	local secondTabIx = g_storeManager:getConstructionTabByName("destinations", "autoDrive").index
	local secondTab = self.items[categoryIx][secondTabIx]
	local thirdTabIx = g_storeManager:getConstructionTabByName("advanced", "autoDrive").index
	local thirdTab = self.items[categoryIx][thirdTabIx]
	local tabs = {
		firstTab,
		secondTab,
		thirdTab
	}

	local brushes = {
		{
			ADBrushMove,
			ADBrushCreate,
			ADBrushConnect,
		},
		{
			ADBrushCreateDestination,
			ADBrushRenameDestination,
			ADBrushDeleteDestination
		},
		{
			ADBrushStraightLine,
			ADBrushCurve
		}
	}
	
	for i,tab in ipairs(brushes) do 
		for j, class in ipairs(tab) do 
			numItems = numItems + 1
			table.insert(tabs[i], {
				price = 0,
				imageFilename = Utils.getFilename(class.imageFilename,AutoDrive.directory),
				name = ADBrush.getName(class),
				brushClass = class,
				brushParameters = {
					ADEditorGUI.ad,
					self.camera
				},
				uniqueIndex = numItems
			})
		end
	end
	return numItems 
end

ConstructionScreen.buildTerrainSculptBrushes = Utils.overwrittenFunction(ConstructionScreen.buildTerrainSculptBrushes,ADEditorGUI.buildTerrainSculptBrushes)

--- Draws the ad network, if the category is selected.
function ADEditorGUI:draw()
	--- Ad category selected
	if self.currentCategory and  self.currentCategory == g_storeManager:getConstructionCategoryByName("autoDrive").index then 

		
		--- Current mouse position.
		local x, y, z = self.cursor:getPosition()

		if x == nil then
			return
		end
		--- Current mouse position.
		ADEditorGUI.ad.position = {
			x,
			y,
			z
		}
		
		--- Some magic draw code below, no idea how this works.
		local distance = MathUtil.vector2Length(x - ADEditorGUI.ad.lastDrawPosition.x, z - ADEditorGUI.ad.lastDrawPosition.z)
		if distance > AutoDrive.drawDistance / 2 or ADGraphManager:hasChanges() then
			ADEditorGUI.ad.lastDrawPosition = {x = x, z = z}
			AdWaypointUtils.resetWayPointsDistance(ADEditorGUI.ad)
		end
		ADEditorGUI.onDrawAD(self)
	else 

	end
end
ConstructionScreen.draw = Utils.appendedFunction(ConstructionScreen.draw, ADEditorGUI.draw)

--- Overrides the destruct button, while ad category is active. 
--- This enables wayPoint deletion with the destruct button.
function ADEditorGUI:setSelectedCategory(superFunc, ix, ...)
	if self.currentCategory == ix then
		return
	end
	local categoryIx = g_storeManager:getConstructionCategoryByName("autoDrive").index
	if categoryIx == ix then 
		self.defaultDestructText = self.buttonDestruct.text
		self.destructBrush = ADBrushDelete.new(nil, self.cursor)
		self.destructBrush:setParameters(
			ADEditorGUI.ad,
			self.camera)
		self.buttonDestruct:setText(ADBrush.getName(self.destructBrush))
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
ConstructionScreen.setSelectedCategory = Utils.overwrittenFunction(ConstructionScreen.setSelectedCategory, ADEditorGUI.setSelectedCategory)

function ADEditorGUI:setBrush(superFunc, brush, ...)
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

ConstructionScreen.setBrush = Utils.overwrittenFunction( ConstructionScreen.setBrush, ADEditorGUI.setBrush)


--- Some magic draw code below, no idea how this works.
function ADEditorGUI:onDrawAD()
	ADDrawUtils.draw(ADEditorGUI.ad)
	ADDrawingManager:draw()

end
