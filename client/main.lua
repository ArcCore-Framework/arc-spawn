AddEventHandler('playerSpawned', function()
  local ped = PlayerPedId()

  local function spawnPlayer(camera, coords)
    DestroyCam(camera)
    ClearFocus()
    RenderScriptCams(false, true, 2000, true, false)

    FreezeEntityPosition(ped, false)
    exports.arc_core:setEntityCoordsAndHeading(ped, coords)
  end

  local ped = PlayerPedId()

  local camPos = vec4(502.77, 5626.79, 792.82, 5.21)
  local cam = CreateCameraWithParams("DEFAULT_SCRIPTED_CAMERA", camPos.xyz, 0.0, 0.0, 0.0, 25.0, true, 2)
  PointCamAtEntity(cam, ped, 0.0, 0.0, 0.0, true)
  RenderScriptCams(true, false, 0, true, true)

  local spawnCoords = vec4(502.21, 5631.69, 792.61 - 1, 187.52)
  exports.arc_core:setEntityCoordsAndHeading(ped, spawnCoords)

  FreezeEntityPosition(ped, true)

  lib.registerContext({
    id = 'arc_spawn_menu',
    title = 'Spawn Selection',
    options = {
      {
        title = 'Sandy Shores',
        description = 'The once great lands of Sandy Shores.',
        onSelect = function()
          spawnPlayer(cam, vec4(1589.70, 3898.83, 32.12, 237.95))
        end,
      },
      {
        title = 'Paleto Bay',
        description = 'Not much to say about this place.',
        onSelect = function()
          spawnPlayer(cam, vec4(-276.96, 6636.61, 7.47, 223.39))
        end,
      },
    },
  })

  lib.showContext('arc_spawn_menu')
end)