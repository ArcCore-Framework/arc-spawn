local cam = nil

local function spawnPlayer(coords)
  local ped = PlayerPedId()

  DestroyCam(cam)
  ClearFocus()
  RenderScriptCams(false, true, 2000, true, false)
  FreezeEntityPosition(ped, false)

  exports.arc_core:setEntityCoordsAndHeading(ped, coords)
end

local function SelectCharacterModel(input)
  local ped = PlayerPedId()
  local curScoll = 1

  lib.registerMenu({
    id = 'character_model_selection',
    title = 'Model Selection',
    position = 'top-right',
    onSideScroll = function(selected, scrollIndex)
      local modelHash = GetHashKey(Config.Models[scrollIndex])
      if IsModelInCdimage(modelHash) and IsModelValid(modelHash) then
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Citizen.Wait(0)
        end
        local plrPed = PlayerId()
        SetPlayerModel(plrPed, modelHash)
        SetPedDefaultComponentVariation(plrPed)
        SetModelAsNoLongerNeeded(modelHash)

        curScoll = scrollIndex
      end
    end,
    onCheck = function(selected, checked, args)
      print("Check: ", selected, checked, args)
    end,
    onClose = function(keyPressed)
      print('Menu closed')
      if keyPressed then
        print(('Pressed %s to close the menu'):format(keyPressed))
      end
    end,
    options = {
      { label = 'Model Selector', description = 'Scroll to select a model', values = Config.Models },
      { label = 'Confirm',        description = 'Confirm the selected model' }
    }
  }, function(selected, scrollIndex, args)
        TriggerServerEvent('arc_core:server:createCharacter', input[1], input[2], Config.FreshSpawnCoords, Config.Models[curScoll])
        spawnPlayer(Config.FreshSpawnCoords)
end)

  lib.showMenu('character_model_selection')
end

local function CreateNewCharacter()
  local input = lib.inputDialog('Character Creator', {
    { type = 'input', label = 'First Name', description = '',             required = true, min = 4,              max = 16 },
    { type = 'input', label = 'Last Name',  description = '',             required = true, min = 4,              max = 16 },
    { type = 'date',  label = 'Date input', icon = { 'far', 'calendar' }, default = true,  format = "DD/MM/YYYY" }
  })

  print(json.encode(input))
  -- local date = os.date('%Y-%m-%d %H:%M:%S', timestamp)
  if input then
    SelectCharacterModel(input)
  end
end

local function CreateCharacterManagerContext(coords, nbid)
  lib.registerContext({
    id = 'arc_spawn_char_manager',
    title = 'Character Manager',
    options = {
      {
        title = 'Spawn Last Location',
        description = 'Spawn at your characters last location.',
        icon = 'fas fa-map-pin',
        onSelect = function()
          spawnPlayer(coords)
        end,
      },
      {
        title = 'Delete Character',
        description = 'This will permantly delete your character!',
        icon = 'fas fa-trash-can',
        onSelect = function()
          local shouldDelete = lib.alertDialog({
            header = '**Are you sure you want to delete this character?**',
            content = 'If you click *confirm* then all of your character progress will be **deleted!**',
            centered = true,
            cancel = true
          })
          if shouldDelete == 'confirm' then
            -- call deelete
            lib.callback.await('arc_core:server:deleteCharacter', false, nbid)
          else
            lib.showContext('arc_spawn_char_manager')
          end
        end,
      },
    },
  })
  lib.showContext('arc_spawn_char_manager')
end

local function CreateCharacterSelector(characters)
  local options = {}

  for i, data in ipairs(characters) do
    local charData = json.decode(data.char_data)

    print(data.coords)
    print(json.encode(data))

    table.insert(options, {
      title = charData.firstName .. " " .. charData.lastName, -- Fixed duplication issue
      description = 'Character NBID: ' .. data.nbid,
      onSelect = function()
        CreateCharacterManagerContext(json.decode(data.coords), data.nbid)
      end,
    })
  end

  -- Add a persistent option to create a new character
  table.insert(options, {
    title = "Create New Character",
    description = "Start fresh with a brand new character",
    onSelect = function()
      CreateNewCharacter() -- Call a function to handle character creation
    end,
  })

  lib.registerContext({
    id = 'arc_spawn_char_menu',
    title = 'Character Selection',
    options = options
  })
  lib.showContext('arc_spawn_char_menu')
end

local function BaseSpawn()
  local ped = PlayerPedId()

  local camPos = vec4(502.77, 5626.79, 792.82, 5.21)
  cam = CreateCameraWithParams("DEFAULT_SCRIPTED_CAMERA", camPos.xyz, 0.0, 0.0, 0.0, 25.0, true, 2)
  PointCamAtEntity(cam, ped, 0.0, 0.0, 0.0, true)
  RenderScriptCams(true, false, 0, true, true)

  local spawnCoords = vec4(502.21, 5631.69, 792.61 - 1, 187.52)
  exports.arc_core:setEntityCoordsAndHeading(ped, spawnCoords)

  FreezeEntityPosition(ped, true)

  local characters = lib.callback.await('arc_core:server:getPlayerCharacters', false)

  if characters == false then
    CreateNewCharacter()
  else
    local decodedData = json.decode(characters[1].char_data)
    local modelHash = GetHashKey(decodedData.model)

    print("Model Hash: " .. modelHash)  -- Debugging model hash

    -- Ensure model is in CD image and valid
    if not IsModelInCdimage(modelHash) then
      print("Model not found in CD image!")  -- Debugging model loading
      return
    end

    if not IsModelValid(modelHash) then
      print("Model is not valid!")  -- Debugging model validity
      return
    end

    -- Request the model
    print("Requesting Model: " .. decodedData.model)  -- Debugging model request
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
      Citizen.Wait(1)
    end


    local plrPed = PlayerId()
    SetPlayerModel(plrPed, modelHash)
    SetPedDefaultComponentVariation(plrPed)

    FreezeEntityPosition(ped, false)
    SetModelAsNoLongerNeeded(modelHash)

    CreateCharacterSelector(characters)
  end
end

RegisterNetEvent('arc_core:client:deleteCharacter', function()
  BaseSpawn()
end)


AddEventHandler('playerSpawned', function()
  Wait(100)
  BaseSpawn()
end)

RegisterCommand('logout', function()
  BaseSpawn()
end, false)
