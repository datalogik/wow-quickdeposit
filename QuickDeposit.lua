local addonName, addon = ...

-- Immediate load message
print("=== QuickDeposit file loaded ===")

QD_ButtonPanel = nil

-- Button configuration
local BUTTON_WIDTH = 75
local BUTTON_HEIGHT = 22
local BUTTON_SPACING = 2
local COLUMN_SPACING = 5

-- Quick amount options (organized in columns - now 2 columns to be narrower)
local depositButtons = {
    -- Column 1
    {
        {label = "All Gold", type = "gold"},
        {label = "All Silver", type = "silver"},
        {label = "All Copper", type = "copper"},
        {label = "5g", copper = 5 * 10000},
        {label = "10g", copper = 10 * 10000},
        {label = "50g", copper = 50 * 10000},
        {label = "100g", copper = 100 * 10000},
    },
    -- Column 2
    {
        {label = "500g", copper = 500 * 10000},
        {label = "1000g", copper = 1000 * 10000},
        {label = "10000g", copper = 10000 * 10000},
        {label = "25%", type = "percent", value = 0.25},
        {label = "50%", type = "percent", value = 0.50},
        {label = "75%", type = "percent", value = 0.75},
        {label = "100%", type = "percent", value = 1.00},
    },
}

local withdrawButtons = depositButtons -- Same layout for withdrawals

-- Helper functions
local function GetPlayerMoney()
    return GetMoney() or 0
end

local function GetBankMoney()
    return C_Bank.FetchDepositedMoney(Enum.BankType.Account) or 0
end

local function CalculateDepositAmount(buttonInfo)
    local playerMoney = GetPlayerMoney()

    if buttonInfo.copper then
        return min(buttonInfo.copper, playerMoney)
    elseif buttonInfo.type == "gold" then
        local gold = floor(playerMoney / 10000)
        return gold * 10000
    elseif buttonInfo.type == "silver" then
        local remainingAfterGold = playerMoney % 10000
        local silver = floor(remainingAfterGold / 100)
        return silver * 100
    elseif buttonInfo.type == "copper" then
        return playerMoney % 100
    elseif buttonInfo.type == "percent" then
        return floor(playerMoney * buttonInfo.value)
    end

    return 0
end

local function CalculateWithdrawAmount(buttonInfo)
    local bankMoney = GetBankMoney()

    if buttonInfo.copper then
        return min(buttonInfo.copper, bankMoney)
    elseif buttonInfo.type == "gold" then
        local gold = floor(bankMoney / 10000)
        return gold * 10000
    elseif buttonInfo.type == "silver" then
        local remainingAfterGold = bankMoney % 10000
        local silver = floor(remainingAfterGold / 100)
        return silver * 100
    elseif buttonInfo.type == "copper" then
        return bankMoney % 100
    elseif buttonInfo.type == "percent" then
        return floor(bankMoney * buttonInfo.value)
    end

    return 0
end

-- Create the button panel
function QD_CreateButtonPanel()
    if QD_ButtonPanel then return end

    -- Calculate panel dimensions
    local numColumns = #depositButtons
    local maxRows = 0
    for _, column in ipairs(depositButtons) do
        maxRows = max(maxRows, #column)
    end

    local panelWidth = (BUTTON_WIDTH * numColumns * 2) + (COLUMN_SPACING * (numColumns * 2 - 1)) + 50
    local panelHeight = (BUTTON_HEIGHT * maxRows) + (BUTTON_SPACING * (maxRows - 1)) + 70

    -- Create main panel
    QD_ButtonPanel = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    QD_ButtonPanel:SetSize(panelWidth, panelHeight)
    QD_ButtonPanel:SetPoint("TOPRIGHT", BankFrame, "BOTTOMRIGHT", -7.5, 7.5)

    QD_ButtonPanel:SetBackdrop({
        bgFile = "Interface/BankFrame/Bank-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 64, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    QD_ButtonPanel:SetBackdropColor(255, 255, 255, 0.8)
    QD_ButtonPanel:SetFrameStrata("LOW")

    -- Create title text
    local title = QD_ButtonPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", QD_ButtonPanel, "TOP", 0, -10)
    title:SetText("Quick Deposit / Withdraw")

    -- Create Deposit label
    local depositLabel = QD_ButtonPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    depositLabel:SetPoint("TOPLEFT", QD_ButtonPanel, "TOPLEFT", 20, -30)
    depositLabel:SetText("|cFF00FF00Deposit|r")

    -- Create Withdraw label
    local withdrawLabel = QD_ButtonPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    withdrawLabel:SetPoint("TOP", depositLabel, "TOP", panelWidth / 2 - 20, 0)
    withdrawLabel:SetText("|cFFFF0000Withdraw|r")

    QD_DrawButtons()
end

function QD_DrawButtons()
    local yStart = -50

    -- Draw Deposit buttons (left side)
    for colIndex, column in ipairs(depositButtons) do
        for rowIndex, buttonInfo in ipairs(column) do
            local btn = CreateFrame("Button", nil, QD_ButtonPanel, "UIPanelButtonTemplate")
            btn:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)

            local xOffset = 20 + ((colIndex - 1) * (BUTTON_WIDTH + COLUMN_SPACING))
            local yOffset = yStart - ((rowIndex - 1) * (BUTTON_HEIGHT + BUTTON_SPACING))

            btn:SetPoint("TOPLEFT", QD_ButtonPanel, "TOPLEFT", xOffset, yOffset)
            btn:SetText(buttonInfo.label)

            btn:SetScript("OnClick", function()
                local amount = CalculateDepositAmount(buttonInfo)
                if amount > 0 then
                    C_Bank.DepositMoney(Enum.BankType.Account, amount)
                end
            end)

            btn.info = buttonInfo
            btn.isDeposit = true

            if not QD_ButtonPanel.depositButtons then
                QD_ButtonPanel.depositButtons = {}
            end
            table.insert(QD_ButtonPanel.depositButtons, btn)
        end
    end

    -- Draw Withdraw buttons (right side)
    local rightSideXStart = 20 + (#depositButtons * (BUTTON_WIDTH + COLUMN_SPACING)) + 20

    for colIndex, column in ipairs(withdrawButtons) do
        for rowIndex, buttonInfo in ipairs(column) do
            local btn = CreateFrame("Button", nil, QD_ButtonPanel, "UIPanelButtonTemplate")
            btn:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)

            local xOffset = rightSideXStart + ((colIndex - 1) * (BUTTON_WIDTH + COLUMN_SPACING))
            local yOffset = yStart - ((rowIndex - 1) * (BUTTON_HEIGHT + BUTTON_SPACING))

            btn:SetPoint("TOPLEFT", QD_ButtonPanel, "TOPLEFT", xOffset, yOffset)
            btn:SetText(buttonInfo.label)

            btn:SetScript("OnClick", function()
                local amount = CalculateWithdrawAmount(buttonInfo)
                if amount > 0 then
                    C_Bank.WithdrawMoney(Enum.BankType.Account, amount)
                end
            end)

            btn.info = buttonInfo
            btn.isDeposit = false

            if not QD_ButtonPanel.withdrawButtons then
                QD_ButtonPanel.withdrawButtons = {}
            end
            table.insert(QD_ButtonPanel.withdrawButtons, btn)
        end
    end
end

function QD_UpdateButtonStates()
    if not QD_ButtonPanel then return end

    local playerMoney = GetPlayerMoney()
    local bankMoney = GetBankMoney()

    -- Update deposit buttons
    if QD_ButtonPanel.depositButtons then
        for _, btn in ipairs(QD_ButtonPanel.depositButtons) do
            local shouldEnable = false

            if btn.info.copper then
                -- Fixed amount: only enable if player has enough
                shouldEnable = playerMoney >= btn.info.copper
            elseif btn.info.type then
                -- Percentages and "All X" types: enable if player has any money
                shouldEnable = playerMoney > 0
            end

            if shouldEnable then
                btn:Enable()
            else
                btn:Disable()
            end
        end
    end

    -- Update withdraw buttons
    if QD_ButtonPanel.withdrawButtons then
        for _, btn in ipairs(QD_ButtonPanel.withdrawButtons) do
            local shouldEnable = false

            if btn.info.copper then
                -- Fixed amount: only enable if bank has enough
                shouldEnable = bankMoney >= btn.info.copper
            elseif btn.info.type then
                -- Percentages and "All X" types: enable if bank has any money
                shouldEnable = bankMoney > 0
            end

            if shouldEnable then
                btn:Enable()
            else
                btn:Disable()
            end
        end
    end
end

-- Event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("BANKFRAME_OPENED")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("ACCOUNT_MONEY")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        print("|cFF00FF00[QuickDeposit]|r Addon loaded event fired!")

        -- Don't hook yet, wait for bank to open
        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "BANKFRAME_OPENED" then
        print("|cFF00FF00[QuickDeposit]|r Bank opened event fired!")
        print("|cFF00FF00[QuickDeposit]|r Searching for bank frames...")

        -- List all Bank-related frames
        local bankFrames = {}
        for name, obj in pairs(_G) do
            if type(obj) == "table" and type(name) == "string" and name:match("Bank") then
                if type(obj.GetObjectType) == "function" then
                    local objType = obj:GetObjectType()
                    if objType == "Frame" or objType == "Button" then
                        table.insert(bankFrames, name)
                        print("  Found:", name)
                    end
                end
            end
        end

        print("|cFF00FF00[QuickDeposit]|r Found " .. #bankFrames .. " bank-related frames")

        -- Try specific frame names
        local possibleFrames = {
            "AccountBankPanel",
            "BankFrameAccountBankPanel",
            "BankSlotsFrame",
            "BankFrame",
        }

        local targetFrame = nil
        for _, frameName in ipairs(possibleFrames) do
            if _G[frameName] then
                print("|cFF00FF00[QuickDeposit]|r Trying frame:", frameName)
                targetFrame = _G[frameName]
                break
            end
        end

        if targetFrame then
            print("|cFF00FF00[QuickDeposit]|r Using frame for hooks")

            if not targetFrame.qdHooked then
                targetFrame.qdHooked = true

                targetFrame:HookScript("OnShow", function()
                    print("|cFF00FF00[QuickDeposit]|r OnShow fired!")
                    QD_CreateButtonPanel()
                    QD_UpdateButtonStates()
                    QD_ButtonPanel:Show()
                end)

                targetFrame:HookScript("OnHide", function()
                    print("|cFF00FF00[QuickDeposit]|r OnHide fired!")
                    if QD_ButtonPanel then
                        QD_ButtonPanel:Hide()
                    end
                end)

                print("|cFF00FF00QuickDeposit|r Hooked! Buttons will appear when you switch to warband bank tab.")
            end

            -- If already shown, create panel now
            if targetFrame:IsShown() then
                print("|cFF00FF00[QuickDeposit]|r Frame already shown, creating panel...")
                QD_CreateButtonPanel()
                QD_UpdateButtonStates()
                QD_ButtonPanel:Show()
            end
        else
            print("|cFFFF0000QuickDeposit|r ERROR: No suitable bank frame found!")
        end

    elseif event == "PLAYER_MONEY" or event == "ACCOUNT_MONEY" then
        -- Money changed, update button states
        QD_UpdateButtonStates()
    end
end)
