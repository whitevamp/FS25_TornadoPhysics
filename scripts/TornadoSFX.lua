TornadoSFX = {}
TornadoSFX.sirenSoundId = nil
TornadoSFX.sirenTimer = 0
TornadoSFX.sirenLoopCount = 0
TornadoSFX.SIREN_LENGTH = 56000
TornadoSFX.isEnabled = true

function TornadoSFX:loadMap(name, baseDir)
    -- Fallback: If baseDir is missing, try the global
    local dir = baseDir or g_currentModDirectory

    print("--------------------------------------------------")
    print("TORNADO SFX: INITIALIZING AUDIO SYSTEM")

    -- Build the path
    self.sirenFile = Utils.getFilename("FX/tornado_siren.ogg", dir)
    TornadoDebug:log(" > Looking for file at: " .. tostring(self.sirenFile))

    if fileExists(self.sirenFile) then
        -- Create the sound sample
        self.sirenSoundId = createSample("TornadoSiren")

        -- Load it as a 2D sound (false)
        local success = loadSample(self.sirenSoundId, self.sirenFile, false)

        if success then
            TornadoDebug:log(" > SUCCESS: Sound ID created (" .. tostring(self.sirenSoundId) .. ")")
        else
            TornadoDebug:log(" > ERROR: File found, but loadSample() failed. (Corrupt OGG?)")
        end
    else
        TornadoDebug:log(" > CRITICAL ERROR: File NOT found! Check your FX folder.")
    end
end

function TornadoSFX:update(dt)
    if self.sirenTimer > 0 then
        self.sirenTimer = self.sirenTimer - dt
    end
end

function TornadoSFX:toggleSound()
    self.isEnabled = not self.isEnabled
    print(string.format("TORNADO SFX: Audio System is now %s", self.isEnabled and "ON" or "MUTED"))
end

function TornadoSFX:playSiren()
    if not self.isEnabled then return end

    -- FAIL CHECK: If ID is nil, we can't play anything
    if self.sirenSoundId == nil then
        TornadoDebug:log("SFX FAIL: No Sound ID loaded. (Did loadMap fail?)")
        return
    end

    if self.sirenLoopCount < 3 and self.sirenTimer <= 0 then
        TornadoDebug:log("SFX", ">>> PLAYING SIREN! <<<")
        playSample(self.sirenSoundId, 1, 1.0, 0, 0, 0)
        self.sirenLoopCount = self.sirenLoopCount + 1
        self.sirenTimer = self.SIREN_LENGTH
    end
end
