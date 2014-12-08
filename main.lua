require("AnAL")
HC = require "hardoncollider"
Gamestate = require "hump.gamestate"
Timer = require "hump.timer"
--Camera = require "hump.camera"
local unpack = unpack or table.unpack


function on_collision(dt, shape_a, shape_b, mtv_x, mtv_y)
	if shape_a.genre == 1 or shape_b.genre == 1 then
		local shape = (shape_a.genre == 1) and shape_a or shape_b
		if shape_a == floor.collider or shape_b == floor.collider then
			local object = shape.parent_entity
			if object.can_jump == false then
				object.vspeed = 0
			    object.y = floor.y - object.hit_height
				--object.y = 
				--print(object.y)
				--print(object.hit_height)
				object.can_jump = true
				object.is_jumping = false
			end
		end
	end
end


function collision_stop(dt, shape_a, shape_b)
	if shape_a.genre == 1 or shape_b.genre == 1 then
		local shape = (shape_a.genre == 1) and shape_a or shape_b
		if shape_a == floor.collider or shape_b == floor.collider then
			local object = shape.parent_entity
			object.can_jump = false
			object.is_jumping = true
		end
	end
end


function love.keypressed(key)
	if key == "left" then
		player.dir = -1
	elseif key == "right" then
		player.dir = 1
	end
end


function love.keyreleased(key)
end


function foe_behaviour(foe)
	foe.behaviour = math.random(1, 10)
	--Timer.add(2, foe_behaviour(foe))
end

function foe_ai(dt)
	for i=1, #foes do
		local foe = foes[i]
		foe.update_behaviour_timer = foe.update_behaviour_timer - dt
		if foe.update_behaviour_timer < 0 then
			foe_behaviour(foe)
			foe.update_behaviour_timer = 2
		end
		
		local player_dir = (player.x > foe.x) and -1 or 1
		local weapon_pos = (player_dir == 1) and player.x+player.width or player.x
		weapon_pos = weapon_pos + player.weapon.length*player_dir/2
		
		if (foe.x+foe.width/2 - weapon_pos)^2 < 5000 then
			if foe.behaviour < 5 then
				--foe.anim = foe_attack
				local var = 0
			end
		else
			::nbehaviour::
			if foe.behaviour < 6 then
				foe.dir = (foe.x < player.x) and 1 or -1
			elseif foe.behaviour < 9 then
				foe.dir = 0
			else 
				foe.dir = (foe.x > player.x) and 1 or -1
			end
		end

		if player.is_jumping == false and foe.is_jumping == false then
			foe.x = foe.x + foe.hspeed * foe.dir * dt
		elseif foe.is_jumping == false then
			foe.x = foe.x + foe.hspeed * foe.dir * dt * 0.5
		end
	end
	
	for i=1, #foes do
		local foe = foes[i]
	    if foe.vspeed ~= 0 then -- if the player vertical velocity (which is negative when jumping) is different from zero then 
			foe.vspeed = foe.vspeed + (dt * world.gravity) -- we increase it (getting it to zero)
	        foe.y = foe.y + (foe.vspeed * dt) -- and change the player vertical position (upward if player.v < 0 and downward otherwise)
		end
		--foes[i] = foe
	end
end


function pop_foe()
	local foe = {}
	local margin = 50
	repeat 
		foe.x = math.random(margin, love.graphics.getWidth()-margin) --
	until (foe.x-player.x)^2 > 10000
	foe.y = 400
	foe.height = 64
	foe.width =  24
	foe.hit_width = 24
	foe.hit_height = 64
	foe.collider = Collider:addRectangle(foe.x, foe.y, foe.hit_width, foe.hit_height)
	foe.collider.type = 4 -- type == foe
	foe.collider.genre = 1
	foe.collider.parent_entity = foe
	foe.dir = (foe.x < player.x) and 1 or -1 -- facing toward player
	foe.vspeed = vspeed
	foe.hspeed = 70
	foe.can_jump = false
	foe.is_jumping = true
	foe.touching_right_wall = false
	foe.touching_left_wall = false
	foe.resistance = math.random(1, 3)
	foe.behaviour = 0
	foe.update_behaviour_timer = 2
	--Timer.addPeriodic(2, foe_behaviour)
	return foe
end


function break_combo()
	score = score + current_combo * current_combo_score
	current_combo = 0
	current_combo_score = 0
end

function max_combo()
	score = score + current_combo * current_combo_score
	for i=1, #foes do
		local foe = foes[i]
		score = score + current_combo
		foe = nil
	end
	foes = nil
	foes = {}
	current_combo = 0
	current_combo = 0 	current_combo_score = 0
	--anim = kill_all
end

function update_colliders(dt)
	for i=1, #foes do
		local foe = foes[i]
		foe.collider:moveTo(foe.x+foe.hit_width/2, foe.y+foe.hit_height/2)
		--foes[i] = foe
	end
	
	player.collider:moveTo(player.x+player.hit_width/2, player.y+player.hit_height/2)
	--player.weapon.collider:moveTo(player.x-10, player.y-10)
	Collider:update(dt)
end	


function love.load()
	-- joystick, window and collider init
	local joysticks = love.joystick.getJoysticks()
    joystick = joysticks[1]
	Collider = HC(100, on_collision, collision_stop)
	math.randomseed(os.time())
	
	effect = love.graphics.newShader [[
	        extern number time;
	        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
	        {
	            return vec4((1.0+sin(time))/2.0, abs(cos(time)), abs(sin(time)), 1.0);
	        }
	    ]]
		
	t = 0
	
	vspeed = 330
	difficulty_level = 1
	foe_timer = 0
	score = 0
	current_combo = 0
	current_combo_score = 0
	spawn_delay = 2
	freeze = false
	
	world = {}
	world.gravity = 600
	
	player = {}
	player.dir = 1 -- facing right
	player.height = 64
	player.width =  24
	player.hit_width = 24
	player.hit_height = 64
	player.x = love.graphics.getWidth()/2-player.width/2
	player.y = 200
	player.collider = Collider:addRectangle(player.x, player.y, player.hit_width, player.hit_height)
	player.collider.type = 1 -- type == player
	player.collider.genre = 1 -- genre == animate_body (foes and player)
	player.collider.parent_entity = player
	player.vspeed = vspeed
	player.hspeed = 330
	player.can_jump = false
	player.is_jumping = true
	player.is_attacking = false
	player.touching_right_wall = false
	player.touching_left_wall = false
	
	player.weapon = {}
	player.weapon.type = "bat"
	player.weapon.length = 60
	--player.weapon.width = 2
	--player.weapon.angle = 0
	--player.weapon.collider = Collider:addRectangle(player.x-10, player.y-10, player.weapon.width, player.weapon.length)
	--player.weapon.collider.type = 5 -- type == weapon]]--
	
	floor = {}
	floor.x = 0
	floor.y = 500
	floor.height = 300
	floor.collider = Collider:addRectangle(floor.x, floor.y, love.graphics.getWidth(), floor.height)
	floor.collider.type = 2 -- type == floor
	
	ceiling = {}
	ceiling.x = 0
	ceiling.y = -100
	ceiling.height = 120
	ceiling.collider = Collider:addRectangle(ceiling.x, ceiling.y, love.graphics.getWidth(), ceiling.height)
	ceiling.collider.type = 3 -- type == ceiling
	
	foes = {}
	foe_color = {}
	foe_color[1] = {220, 20, 20}
	foe_color[2] = {20, 220, 20}
	foe_color[3] = {20, 20, 220}
	
	
	particle_image = love.graphics.newImage("particle.png")
	particles = love.graphics.newParticleSystem(particle_image, 200)
	particles:start()
	particles:setEmissionRate(25)
	particles:setSizes(10, 0)
	particles:setPosition(0, 20)
	particles:setAreaSpread("uniform", 10, 10)
	particles:setInsertMode("random")
	particles:setRotation(math.pi * 1.5)
	--particles:setParticleLifetime(lifeTime)
	particles:setDirection(math.pi)
	particles:setColors(255, 255, 255, 25)
end


function love.update(dt)
    Timer.update(dt)
	local current_time = love.timer.getTime()
	
	t = t + dt
	effect:send("time", t)
	particles:update(dt)
	
	if freeze == false then
		foe_timer = foe_timer + dt
		if foe_timer >= spawn_delay then
			foe_timer = foe_timer - spawn_delay
			foe = pop_foe()
			foes[#foes+1] = foe
		end
	
		foe_ai(dt)

		if player.vspeed ~= 0 then -- if the player vertical velocity (which is negative when jumping) is different from zero then 
			player.vspeed = player.vspeed + (dt * world.gravity) -- we increase it (getting it to zero)
			player.y = player.y + (player.vspeed * dt) -- and change the player vertical position (upward if player.v < 0 and downward otherwise)
		end
	
		if love.keyboard.isDown(" ") and player.can_jump then -- or (joystick ~= nil and joystick:isGamepadDown("a"))
			player.vspeed = -vspeed
			--player.is_jumping = true
		end
	 
		if (love.keyboard.isDown("right") and player.touching_right_wall == false) or (love.keyboard.isDown("left") and player.touching_left_wall == false) then
			player.x = player.x + player.hspeed * player.dir * dt
		end
	
		if love.keyboard.isDown("a") then
			local weapon_pos = (player.dir == 1) and player.x+player.width or player.x
			weapon_pos = weapon_pos + player.weapon.length*player.dir/2
			weapon_aim = 1 -- horizontal hit
			if love.keyboard.isDown("up") then
				weapon_aim = 2 -- upward hit
			elseif love.keyboard.isDown("down") then
				weapon_aim = 3 -- downward hit
			end
			
			for i=#foes, 1, -1 do
				local foe = foes[i]
				--print(player.dir)	
				print("foe.resistance"..foe.resistance)
				print("weapon_aim"..weapon_aim)
				if (foe.x+foe.width/2 - weapon_pos)^2 < 5000 then --+ (foe.y+foe.height/2 - player.y+player.height/2)^2 < 5000 then
					--if player.is_attacking == false then
					if foe.resistance ~= weapon_aim then
						table.remove(foes, i)
						if break_combo_handle then
							Timer.cancel(break_combo_handle)
						end
						current_combo = current_combo + 1 
						current_combo_score = current_combo_score + 1
						print("current combo"..current_combo)
						if current_combo > 20 then
							max_combo()
							break
						else
							break_combo_handle = Timer.add(2, break_combo)
							Timer.add(0.6, function() if freeze then freeze = false end end)
							if spawn_delay > 0.7 then
								spawn_delay = spawn_delay - spawn_delay/10
							end
							--freeze = true
						end
					end
						--freeze = true
						--strike()
						--end
					--current_animation = swing_weapon	
				end
			end
		end
	
		update_colliders(dt)
	
	end
    --if player.vspeed == 0 then
        --current_animation = walk_animation
	--end
	
end


function love.draw()
    --love.graphics.setShader(effect)
	
    --love.graphics.setColor(200, 20, 20)
	player.collider:draw('line')
    --love.graphics.setColor(255, 255, 255)
	--love.graphics.rectangle("line", player.x, player.y, player.width, player.height)
	floor.collider:draw('line')
	ceiling.collider:draw('line')
	
	--player.weapon.collider:draw('line')
	
	love.graphics.print("SCORE "..score, love.graphics.getWidth()/2, 100)
	love.graphics.print("COMBO "..current_combo, love.graphics.getWidth()/2, 150)
	
	for i=1, #foes do
		local foe = foes[i]
		love.graphics.setColor(unpack(foe_color[foe.resistance]))
		foe.collider:draw("line")
		love.graphics.setColor(255, 255, 255)
		--love.graphics.rectangle("line", foe.x, foe.y, foe.width+2, foe.height+2)
	end	
	
	if freeze then
		love.graphics.circle("line", player.x+player.width/2+player.weapon.length*player.dir, player.y+player.height/2, 10)
		--love.graphics.draw(particles, player.x+player.width/2+player.weapon.length*player.dir, player.y+player.height/2)
	end
	
end


function load_sprites()
    p1_spritesheet = love.image.newImageData("p1_spritesheet.png")
    p1_coordinates = {}
    
    file = love.filesystem.newFile("p1_spritesheet.txt")
    file:open("r")
    lines = file:lines()
    for line in lines do
        local key, p1, p2, p3, p4 = string.match(line, "(%a%d%p%a+%d*)%s*=%s*(%d+)%s*(%d+)%s*(%d+)%s(%d+)")
        p1_coordinates[key] = {p1, p2, p3, p4}
    end

        
    p1_walk_sprites = love.image.newImageData(11*72, 97)
    walk_names = { "p1_walk01", "p1_walk02", "p1_walk03", "p1_walk04", "p1_walk05", "p1_walk06", "p1_walk07", "p1_walk08", "p1_walk09", "p1_walk10", "p1_walk11" }

    for i=1, #walk_names do
        name = walk_names[i]
        local sx, sy, sw, sh = (p1_coordinates[name])[1], (p1_coordinates[name])[2],(p1_coordinates[name])[3], (p1_coordinates[name])[4] 
        print(sx, sy, sw, sh)
        p1_walk_sprites:paste(p1_spritesheet, 72*(i-1), 0, sx, sy, sw, sh)
    end

    p1_walk_sprites = love.graphics.newImage(p1_walk_sprites)
    walk_animation = newAnimation(p1_walk_sprites, 72, 97, 0.01, 0)

    jump_name = "p1_jump"
    p1_jump_sprites = nil
    sx, sy, sw, sh = (p1_coordinates[jump_name])[1], (p1_coordinates[jump_name])[2],(p1_coordinates[jump_name])[3], (p1_coordinates[jump_name])[4]
    print("jump", sx, sy, sw, sh)
    p1_jump_sprites = love.image.newImageData(sw, sh)
    p1_jump_sprites:paste(p1_spritesheet, 0, 0, sx, sy, sw, sh)
    p1_jump_sprites = love.graphics.newImage(p1_jump_sprites)
    jump_animation = newAnimation(p1_jump_sprites, sw, sh, 0.1, 0)
    current_animation = walk_animation
end
