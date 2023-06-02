function functions()
    function modeDetect()
        if mode == 'game' then
            win.scene:action(function()
                if win:key_pressed('escape') then
                    win.scene:remove_all()
                    win.scene:append(am.group() ^ menuGroup())
                    mode = 'menu'
                end
            end)
        end
        if mode == 'menu' then
            if win:mouse_pressed('left') then
                if win:mouse_position()[1] < -width/2+10 and win:mouse_position()[2] < -height/2+10 then
                    win.scene:remove_all()
                    win.scene:append(am.group(gameplayGroup()))
                    mode = 'stress_test'
                    log('clicked')
                end
            end
            for i, button in pairs(startButtons) do
                repeat
                    if i % 2 ~= 1 then break end
                    if buttonclicks(startButtons[i], startButtons[i+1]) ~= true then break end
                    restartGame()
                    if i == 1 then
                        win.scene:remove_all()
                        win.scene:append(am.group(gameplayGroup()))
                        mode = 'game'
                    end
                    if i == 3 then
                        win:close()
                        win.scene:remove_all()
                        win.scene:append(am.group(upgradesGroup()))
                        mode = 'upgrades'
                    end
                    if i == 5 then
                        win.scene:remove_all()
                        settingsGroup = setSettingsGroup()
                        win.scene:append(am.group(settingsGroup))
                        mode = 'settings'
                        return group
                    end
                until true
            end
        end
        if mode == 'settings' then
            win.scene:action(function()
	            if win:key_pressed('escape') then
                    win.scene:remove_all()
                    win.scene:append(am.group() ^ menuGroup())
                    saveSettings()
                    mode = 'menu'
                end
            end)
        end
    end
    function restartGame()
	    loludiedtext"text".text = ''
        speed = 0
        slowingStamina = 0
        Bullets:remove_all()
            
        dead = nil
        toggle = nil
        isslow = 0
        speed = 0
        charx = 0
        chary = 0
        count = 0
        score = 0
        Score = 0
        if Explosions ~= nil then
            Explosions:remove_all()
        end
        if explosion ~= nil then
            explosion:remove_all()
        end
        explanationtext'text'.text = 'You are a hollow white square\nYour goal is to dodge white squares\nYou no need to dodge yourself so relax:)'
    end
    function addBullet(bullet, i, x0ory1)
        win.scene:action(am.play(am.sfxr_synth(300), false, (count+1) ^ 0.05/3 * pitch, volume))
        local x, y = 0, 0
        if x0ory1 == 0 then
            if bullet.x > 0 then
                x = width/2 -1
            else
                x = -width/2 +1
            end
            y = bullet.y
        else
            if bullet.y > 0 then
                y = height/2-1
            else
                y = -height/2+1
            end
            x = bullet.x
        end
        local power
        if mode == 'game' then power = 0.2 else power = 0.01 end
        if (math.abs(bullet.x) < width * 0.4 or math.abs(bullet.y) < height * 0.4) and math.random() <= 1/count ^ power then
            count = count + 1
            Bullets:append(am.translate(x, y) ^ am.scale(10) ^ am.sprite(bulletsprite))
        end
        if x0ory1 == 0 then
            Bulletsspeed[i] = {deltax(x), Bulletsspeed[i][2], Bulletsspeed[i][3]}
            Bulletsspeed[#Bulletsspeed+1] = {Bulletsspeed[i][1], -Bulletsspeed[i][2]}
        else
            Bulletsspeed[i] = {Bulletsspeed[i][1], deltay(y), Bulletsspeed[i][3]}
            Bulletsspeed[#Bulletsspeed+1] = {-Bulletsspeed[i][1], Bulletsspeed[i][2]}
        end
        if Bulletsspeed[i][2] == 0 then
            Bulletsspeed[i][2] = math.random()
        end
        Bulletsspeed[#Bulletsspeed][3] = 0
        Bulletsspeed[i][3] = Bulletsspeed[i][3] + 1
    end
    function moveBullet(bullet, i)
        local ismoving
        if dead then
            ismoving = 0
        else
            ismoving = 1
        end
        bullet.x = bullet.x + Bulletsspeed[i][1] * speed * 3 * ismoving
        bullet.y = bullet.y + Bulletsspeed[i][2] * speed * 3 * ismoving
        if bullet.x > width/2 then
            bullet.x = width/2
        elseif bullet.x < -width/2 then
            bullet.x = -width/2
        end
        if bullet.y > height/2 then
            bullet.y = height/2
        elseif bullet.y < -height/2 then
            bullet.y = -height/2
        end
    end
    function spawnexplosion(dyingbulletcoordinates)
        if math.random() > 0 then
        local coords = vec2(charx + math.random(-10, 10)*10, chary + math.random(-10, 10)*10)
        local x = coords[1]
        local y = coords[2]
        local line = am.line(dyingbulletcoordinates, coords, 1, vec4(1, 0, 0, 1))
        local halfline = am.line(dyingbulletcoordinates, vec2((dyingbulletcoordinates[1] + x)/2, (dyingbulletcoordinates[2] + y)/2), 1, vec4(1, 0, 0, 1))
        local explosionPreparing = am.circle(coords, 2, vec4(1, 0, 0, 0.5))
        local explosion = am.circle(coords, 20, vec4(1, 0, 0, 0.5))
        Explosions:action(am.series{
            function()
                Explosions:action(am.play(am.sfxr_synth(103), false, pitch, volume))
                Explosions:append(halfline)
                return true
            end,
            am.delay(0.05),
            function()
                Explosions:remove(halfline)
                Explosions:append(line)
                return true
            end,
            am.delay(0.05),
            function()
                Explosions:remove(line)
                Explosions:append(explosionPreparing)
                return true
            end,
            am.delay(1),
            function()
                Explosions:action(am.play(am.sfxr_synth(102), false, pitch, volume))
                Explosions:remove(explosionPreparing)
                Explosions:append(explosion)
                spawnHittingParticles(x, y, vec4(1, 0, 0, 1))

                local charx = character.position2d[1]
                local chary = character.position2d[2]
                if math.abs(x - charx) < 40 and math.abs(y - chary) < 40 and mode ~= 'stress_test' then
                    character:action(am.play(am.sfxr_synth(102), false, pitch/2, volume))
                    dead = 0
                    speed = 1
                end

                return true
            end,
            am.delay(0.1),
            function()
                Explosions:remove(explosion)
                return true
            end,
        })
        end
    end
    function checkForCollision(bullet, type)
        local charx = character.position2d[1]
        local chary = character.position2d[2]
        if math.abs(bullet.position2d[1] - charx) < 20 and math.abs(bullet.position2d[2] - chary) < 20 and mode ~= 'stress_test' then
            character:action(am.play(am.sfxr_synth(102), false, pitch/2, volume))
            dead = 0
            speed = 1
        end
    end
    function deltax(x)
        if not x then
            x = 0
        end
        if x > 0 then
            return -math.random() * 2 - 1
        else
            return math.random() * 2 + 1
        end
    end
    function deltay(y)
        if not y then
            y = 0
        end
        if y > 0 then
            return -math.random() * 2 - 1
        else
            return math.random() * 2 + 1
        end
    end
    function spawnHittingParticles(x, y, color)
        if not color then
            color = vec4(1, 1, 1, 0.6)
        end
        local hittingparticle = 
            am.blend("add_alpha")
            ^ am.particles2d{
                source_pos = vec2(x, y),
                source_pos_var = vec2(2, 2),
                max_particles = 20,
                emission_rate = 200,
                start_particles = 0,
                life = 0.1,
                life_var = 0.1,
                angle = math.rad(90),
                angle_var = math.rad(180),
                speed = 200,
                start_color = color,
                start_color_var = vec4(0, 0, 0, 0.3),
                end_color = vec4(1, 1, 1, 0),
                start_size = 5,
                start_size_var = 2,
                end_size = 5,
                end_size_var = 2,
                warmup_time = 0.05,
            }
	    Bullets:action(am.series{
        function()
            hittingparticles:append(hittingparticle)
            return true
        end,
        am.delay(0.1),
        function()
            hittingparticle'particles2d'.emission_rate = 0;
            return true
        end,

        function()
            if hittingparticle.active_particles == 0 then
                hittingparticles:remove(hittingparticle)
                return true
            end
        end,
        })
    end
    function buttonclicks(button, text)
        local bstclr = button.color
        local txtstclr = text'text'.color
        local x1 = button.x1
        local x2 = button.x2
        if x1 > x2 then
            x1, x2 = x2, x1
        end
        local y1 = button.y1
        local y2 = button.y2
        if y1 > y2 then
            y1, y2 = y2, y1
        end
        local mousex = win:mouse_position()[1]
        local mousey = win:mouse_position()[2]
        if mousex > x1 and mousex < x2 and mousey > y1 and mousey < y2 then
            button.color = startButtonsColors[3]
            text.color = startButtonsColors[4]
            if win:mouse_pressed('left') then
                mode = 'game'
                return true
            end
        else
            button.color = startButtonsColors[1]
            text'text'.color = startButtonsColors[2]
        end
        return nil
    end
    function gameplayGroup()
        local group = 
        {
            staminaBar,
            staminaOrbs,
            hittingparticles,
            character,
            Bullets,
            Explosions,
            speedtext,
            loludiedtext,
            explanationtext,
        }
        return group
    end
    function upgradesGroup()
    end
    function setSettingsGroup()
        local group = {
            am.translate(0, 300) ^ am.scale(5) ^ am.text('Volume'),
            am.rect(-500, 250, 500, 230, vec4(1, 1, 1, 0.5)),
            am.rect(-510, 270, -490, 210), -- slider1 at position 3
            am.translate(0, 180) ^ am.scale(4) ^ am.text('Screen mode'),
            am.rect(-500, 150, -30, 100, vec4(1, 1, 1, .5)), --button1 at position 5
            am.rect(500, 150, 30, 100, vec4(1, 1, 1, 0.5)), --button2 at postion 6
            am.translate(-265, 125) ^ am.scale(3) ^ am.text('Fullscreen', startButtonsColors[2]),
            am.translate(265, 125) ^ am.scale(3) ^ am.text('Borderless', startButtonsColors[2]),
        }
        local width = group[3].x2 - group[3].x1
        group[3].x1 = volume * (group[2].x2 - group[2].x1) - width/2 + group[2].x1
        group[3].x2 = group[3].x1 + width
        if win.mode == 'fullscreen' then
            group[5].color = vec4(1, 1, 1, .8)
            group[6].color = vec4(1, 1, 1, .4)
        elseif win.mode == 'windowed' then
            group[5].color = vec4(1, 1, 1, .4)
            group[6].color = vec4(1, 1, 1, .8)
        end
        return group
    end
    function settingsAction()
        local function buttonCovering(button)
            local x1 = button.x1
            local x2 = button.x2
            local x = win:mouse_position()[1]
            if math.max(x1, x2) > x and math.min(x1, x2) < x then
                return true
            end
     	end
        local function sliderClicking(slider)
            local x1 = slider.x1
            local x2 = slider.x2
            local y1 = slider.y1
            local y2 = slider.y2
            if x1 > x2 then
                x1, x2 = x2, x1
            end
            if y1 > y2 then
                y1, y2 = y2, y1
            end
            local mousex, mousey = win:mouse_position()[1], win:mouse_position()[2]
            if mousex >= x1 and mousex <= x2 and mousey >= y1 and mousey <= y2 then
                if win:mouse_pressed('left') then
                    return 1
                end
            end
        end
        local function sliderMoving(slider)
            local width = slider.x2 - slider.x1
            local x = win:mouse_position()[1]
            slider.x1 = x - width/2
            slider.x2 = x + width/2
            local leftedge = settingsGroup[2].x1
            local rightedge = settingsGroup[2].x2
            if slider.x1 < leftedge-width/2 then
                slider.x1 = leftedge -width/2
                slider.x2 = leftedge + width/2
            elseif slider.x2 > rightedge+width/2 then
                slider.x1 = rightedge - width/2
                slider.x2 = rightedge + width/2
            end
            return nil
        end


        local mousexy = win:mouse_position()
            local mousex = mousexy[1]
            local mousey = mousexy[2]
        local slider1 = settingsGroup[3]
        local volumevar = settingsGroup[2].x2 - settingsGroup[2].x1
        local width = slider1.x2 - slider1.x1
        local volumeold = volume
        local button1 = settingsGroup[5]
        local button2 = settingsGroup[6]
        volume = (slider1.x1 + width/2 - settingsGroup[2].x1) / volumevar

        if sliderClicking(slider1) or clicked then
            clicked = 1
            sliderMoving(slider1)
            if win:mouse_released('left') then
                clicked = nil
            end
        end
        if volumeold ~= volume then
            win.scene:action(am.play(am.sfxr_synth(300), false, pitch/2, volume))
        end
        if sliderClicking(button1) then
            win.mode = 'fullscreen'
            button1.color = vec4(1, 1, 1, 0.8)
            button2.color = vec4(1, 1, 1, 0.4)
        elseif sliderClicking(button2) then
            win.mode = 'windowed'
            button1.color = vec4(1, 1, 1, 0.4)
            button2.color = vec4(1, 1, 1, 0.8)
        end
    end
    function menuGroup()
        startButtonsColors = {
            vec4(0.5, 0.5, 0.7, 1),
            vec4(1, 1, 0, 0.7),
            vec4(0.5, 0.5, 0.7, 0.5),
            vec4(1, 1, 0, 0.7),
        }
        startButtons = {
            am.rect(-200, -80, 200, 0, startButtonsColors[1]),
            am.translate(0, -40) ^ am.scale(5) ^ am.text('start', startButtonsColors[2]),
            am.rect(-200, -100, 200, -180, startButtonsColors[1]),
            am.translate(0, -140) ^ am.scale(5) ^ am.text('quit', startButtonsColors[2]),
            am.rect(-200, -200, 200, -280, startButtonsColors[1]),
            am.translate(0, -240) ^ am.scale(5) ^ am.text('settings', startButtonsColors[2]),
        }
        local group = startButtons
        return group
    end
    function loadSettings()
        local settingsFilePath = "C:\\Users\\"..os.getenv('USERNAME').."\\AppData\\LocalLow\\ULTRADODGER\\settings.txt"
        local settingsFile = io.open(settingsFilePath)
        local screenMode
        if settingsFile then
            volume = settingsFile:read('*line')
            screenMode = settingsFile:read('*line')
            settingsFile:close()
        end
        if volume and screenMode then
            win.mode = screenMode
        else
            mode = 'settings'
            win.scene:remove_all()
            settingsGroup = setSettingsGroup()
            win.scene:append(am.group(settingsGroup))
            return nil
        end
    end
    function saveSettings()
        local settingsFilePath = "C:\\Users\\"..os.getenv('USERNAME').."\\AppData\\LocalLow\\ULTRADODGER\\settings.txt"
        local volume = volume
        local screenMode = win.mode
        local settingsFile = io.open(settingsFilePath, 'w')
        if settingsFile then
            settingsFile:write(volume..'\n')
            settingsFile:write(screenMode..'\n')
            settingsFile:close()
        end
        return nil
    end
    function sendStaminaOrb(x, y)
        local orb = am.circle(vec2(x, y), 5, vec4(0.8, 0.8, 1, 0.5))
        orbTrajectoryCounter[#orbTrajectoryCounter + 1] = 0
        staminaOrbs:append(orb)
    end
    function startGame()
        local function spawnBullet()
            local angle = Bullets.num_children / 3 * math.pi
            local bullet = am.translate(math.cos(angle) * 100, math.sin(angle) * 100) ^ am.scale(10) ^ am.sprite(bulletsprite)
            Bulletsspeed[#Bulletsspeed+1] = {math.random(bullet.position2d[1]), math.random(bullet.position2d[1]), 0}
            Bullets:append(bullet)
        end
        local degrees = 0
        Bulletsspeed = {}
	    Bullets:action(am.series{
            function()
                spawnBullet()
                spawnBullet()
                spawnBullet()
                spawnBullet()
                spawnBullet()
                spawnBullet()
                spawnBullet()
                spawnBullet()
                spawnBullet()
                spawnBullet()
                spawnBullet()
                return true
            end,
            am.delay(0.1),
        })
    end
end

functions()

function initializeVariablesDeclaration()
    local function window()
        width = 1920
        height = 1080
        size = vec2(width, height)
        win = am.window{
        title = "ULTRADODGER",
        width = width,
        height = height,
        mode = "fullscreen",
        clear_color = vec4(0, 0, 0, 1),
        }
    end
    local function sprites()
        charactersprite = [[
                            WWWW
                            W..W
                            W..W
                            WWWW
                            ]]

        bulletsprite = [[
                        W
                        ]]
    end
    local function stats()
        math.randomseed(os.clock())
        x, y = 100, 200
        speed = 0
        count = 0 
        isslow = 0
        mode = 'menu'
        volume = 0
        pitch = 1
        slowingStamina = 0
    end
    local function nodesAndObjects()
        local function fcharacter()
            charx, chary = 0, 0
            character = am.translate(0,0) ^ am.scale(10) ^ am.sprite(charactersprite)
        end
        local function groups()
            Explosions = am.group()

            Bullets = am.group()

            Bulletsspeed = {}
            Bulletsspeed[1] = {deltax(), deltay(), 0}
        end
        local function particles()
            staminaOrbs = am.group()
            hittingparticles = am.group()
            orbTrajectoryCounter = {}
        end
        local function buttons()
            startButtonsColors = {
                vec4(0.5, 0.5, 0.7, 1),
                vec4(1, 1, 0, 0.7),
                vec4(0.5, 0.5, 0.7, 0.5),
                vec4(1, 1, 0, 0.7),
            }
            startButtons = {
                am.rect(-200, -80, 200, 0, startButtonsColors[1]),
                am.translate(0, -40) ^ am.scale(5) ^ am.text('start', startButtonsColors[2]),
                am.rect(-200, -100, 200, -180, startButtonsColors[1]),
                am.translate(0, -140) ^ am.scale(5) ^ am.text('upgrades', startButtonsColors[2]),
                am.rect(-200, -200, 200, -280, startButtonsColors[1]),
                am.translate(0, -240) ^ am.scale(5) ^ am.text('settings', startButtonsColors[2]),
            }
            
        end
        local function others()
            staminaBar = am.rect(0, 20-height/2, 0, 10-height/2, vec4(1, 1, 1, 1))
        end
        local function texts()
            explanationtext = am.scale(2) ^ am.translate(0, height/8) ^ am.text('You are a hollow white square\nYour goal is to dodge white squares\nYou no need to dodge yourself so relax:)')
            speedtext = am.scale(2) ^ am.translate(0, -height/8) ^ am.text("Space to hide this hint and start\nAWSD to move\nShift to slow time down")
            loludiedtext = am.scale(10) ^ am.text('', vec4(1, 0, 0, 1))
        end
        particles()
        buttons()
        fcharacter()
        texts()
        groups()
        others()
    end
    window()
    sprites()
    stats()
    nodesAndObjects()
end
initializeVariablesDeclaration()

staminaBar:action(function()
    for i = staminaOrbs.num_children, 1, -1 do
        local orb = staminaOrbs:child(i)
        local Xa = orb.center[1]
        local Xb = charx
        local Ya = orb.center[2]
        local Yb = chary
        local lambda = 100/((math.abs(Xa - Xb) + math.abs(Ya - Yb))/2)
        local newx = (Xa + lambda * Xb) / (lambda + 1)
        local newy = (Ya + lambda * Yb) / (lambda + 1)
        orb.center = vec2(newx, newy)
        if (math.abs(Xa - Xb) + math.abs(Ya - Yb)) <= 20 then
            staminaOrbs:remove(orb)
        end
    end
end)

character:action(function()
    staminaBar.x1 = slowingStamina / 120 * width * (-1)
    staminaBar.x2 = slowingStamina / 120 * width
    if not dead then
        local dt = am.delta_time
        if (win:key_down"d" or win:key_down"a") and (win:key_down"s" or win:key_down"w") then
            isdiagonal = 0.70710678118
        else
            isdiagonal = 1
        end
        if win:key_down"d" and not win:key_down"a" then
            charx = charx + dt * 400 * isdiagonal * isslow * speed
        end
        if win:key_down"a" and not win:key_down"d" then
            charx = charx - dt * 400 * isdiagonal * isslow * speed
        end
        if win:key_down"w" and not win:key_down"s" then
            chary = chary + dt * 400 * isdiagonal * isslow * speed
        end
        if win:key_down"s" and not win:key_down"w" then
            chary = chary - dt * 400 * isdiagonal * isslow * speed
        end
        if charx + 15 > width / 2 then
            charx = width / 2 - 15
        elseif charx - 15 < -width / 2 then
            charx = -width / 2 + 15
        end

        if chary + 15 > height / 2 then
            chary = height / 2 - 15
        elseif chary - 15 < - height / 2 then 
            chary = - height / 2 + 15
        end
        if toggle then
            if win:key_down('lshift') and slowingStamina > 0 then
                slowingStamina = slowingStamina - 1/5
                pitch = 0.5
                speed = 0.5
                if not BGcolorCounter then BGcolorCounter = 0 end
                BGcolorCounter = BGcolorCounter + 0.5
                if BGcolorCounter > 10 then BGcolorCounter = 10 end
                win.clear_color = vec4(0, 0, BGcolorCounter / 50, 0.2)
            else
                pitch = 1
                speed = 1
                if not BGcolorCounter then BGcolorCounter = 0 end
                BGcolorCounter = BGcolorCounter - 0.5
                if BGcolorCounter < 0 then BGcolorCounter = 0 end
                win.clear_color = vec4(0, 0, BGcolorCounter/50, 0.2)
            end
        end
        if not toggle then
            speedtext"text".text = "Space to hide this hint and start\nAWSD to move\nShift to slow time down\nScore: " .. #Bulletsspeed
        else
            speedtext"text".text = '\nScore: ' .. #Bulletsspeed
            if not score then
                score = 0
            end
            speedtext.scale = vec3(2 * (score+1), 2 * (score+1), 2 * (score+1))
        end
        if win:key_pressed('space') and not toggle then
            startGame()
            toggle = 0
            isslow = 1
            speed = 1
            explanationtext'text'.text = ''
        elseif win:key_pressed('space') and toggle then
            toggle = nil
            isslow = 0
            speed = 0
            explanationtext'text'.text = 'You are a hollow white square\nYour goal is to dodge white squares\nYou no need to dodge yourself so relax:)'
            speedtext"text".text = ""
        end
    else
        pitch = 1
        speed = 1
        if not BGcolorCounter then BGcolorCounter = 0 end
        BGcolorCounter = BGcolorCounter - 0.5
        if BGcolorCounter < 0 then BGcolorCounter = 0 end
        win.clear_color = vec4(0, 0, BGcolorCounter/50, 0.2)
        loludiedtext"text".text = 'LOL U DIED'
        speedtext"text".text = 'Score: ' .. #Bulletsspeed .. '\nPress R to Restart\nPress Escape to Quit'
        if win:key_pressed'r' then
            restartGame()
        end
    end

    
    

    character.position2d = vec2(charx, chary)
end)

Bullets:action(function()
    
    
    if not dead then
        for i = Bullets.num_children, 1, -1 do
            bullet = Bullets:child(i)
            if bullet.x >= width/2 then
                addBullet(bullet, i, 0)
            end

            if bullet.x <= -width/2 then
                addBullet(bullet, i, 0)
            end

            if bullet.y >= height/2 then
                addBullet(bullet, i, 1)
            end

            if bullet.y <= -height/2 then
                addBullet(bullet, i, 1)
            end

            local dt = am.delta_time


            moveBullet(bullet, i)
            if Bulletsspeed[i][3] > 2 and count > 1 then
                local xy = bullet.position2d
                sendStaminaOrb(xy[1], xy[2])
                slowingStamina = slowingStamina + 1
                if slowingStamina > 60 then
                    slowingStamina = 60
                end
                spawnHittingParticles(xy[1], xy[2])
                table.remove(Bulletsspeed, i)
                Bullets:remove(bullet)
                count = count - 1
                if math.random() > 0.8 then
                    spawnexplosion(xy)
                end
            end
            checkForCollision(bullet)
        end
    end
end)

win.scene = am.group() ^ menuGroup()

loadSettings()

win.scene:action(function()
    modeDetect()
    local mode = mode
    if mode == 'settings' then
        settingsAction()
    end
end)