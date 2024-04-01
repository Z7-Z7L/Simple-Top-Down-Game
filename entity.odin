package game

import rl "vendor:raylib"
import "core:fmt"
import "core:math"

Entity_Id :: distinct u32;

Entity_System :: struct {
  id_counter: Entity_Id,
  entities: map[Entity_Id]Entity,
}

Player :: struct {
  speed    : f32,
  center   : rl.Vector2,
}

Enemy :: struct {
  speed : f32,
}

Gun :: struct {
  ammo          : i32,
  rotation      : f32,
  shootingPoint : rl.Vector2,
}

Bullet :: struct {
  shooted  : bool,
}

Entity_Variant :: union {Player, Enemy, Gun, Bullet};

Entity :: struct {
  position : rl.Vector2,
  velocity : rl.Vector2,
  hitbox   : rl.Rectangle,
  id       : Entity_Id,
  variant  : Entity_Variant,
}

Update_Entity :: proc(e: ^Entity, deltaTime: f32) {
  // Mouse Position
  mousePos := rl.GetMousePosition();

  switch v in &e.variant {
    case Player: {
      // Get Player Center
      v.center = rl.Vector2{e.position.x + 30, e.position.y + 30};

      /*** Movement ***/
      if (rl.IsKeyDown(.D))      {e.velocity.x =  v.speed;}
      else if (rl.IsKeyDown(.A)) {e.velocity.x = -v.speed}
      else {e.velocity.x = 0;}

      if (rl.IsKeyDown(.W))      {e.velocity.y = -v.speed;}
      else if (rl.IsKeyDown(.S)) {e.velocity.y =  v.speed;}
      else {e.velocity.y = 0;}
      /*** Movement ***/

      // Border
      if (e.position.x < -11)       {e.position.x = 1871;}
      else if (e.position.x > 1871) {e.position.x = -11;}
      if (e.position.y < -11)       {e.position.y = 1031;}
      else if (e.position.y > 1031) {e.position.y = -11;}

      // Enemy
      for _,otherEntity in entity_system.entities {
        if (rl.CheckCollisionRecs(e.hitbox, otherEntity.hitbox)) {
          switch q in otherEntity.variant {
            case Enemy: {
              currentScene = GameScene.DEATH_MENU;
              currentLevel = GameLevel.LEVEL1;
            } break;
            case Player: {} break;
            case Bullet: {} break;
            case Gun: {} break;
          }
        }
      }

      // Reset Position If The Game Starts
      if (currentScene == GameScene.MAIN_MENU || currentScene == GameScene.END_MENU || currentScene == GameScene.DEATH_MENU) {
        e.position = {250,250};
      }

      // Apply Velocity & Hitbox Position
      e.position += e.velocity * deltaTime;
      e.hitbox.x = e.position.x;
      e.hitbox.y = e.position.y;
    } break;
    case Enemy: {
      p := Get_Entity(1);
      if (p != nil) {
        direction:  rl.Vector2 = p.position - e.position;
        direction = rl.Vector2Normalize(direction);

        e.velocity = direction * v.speed;

        if (len(e.velocity) > 60) {
          e.velocity = rl.Vector2Normalize(e.velocity) * v.speed;
        }
      }
      
      // Update Velocity & Hitbox Position
      e.position += e.velocity * deltaTime;
      e.hitbox.x = e.position.x;
      e.hitbox.y = e.position.y;
    } break;
    case Gun: { 
      // Rotate the gun to face the mouse  
      p := Get_Entity(1);
      if (p != nil) {
        p_center := p.variant.(Player).center;
        e.position = RotatePointAroundCenter(p_center, mousePos, 70);
        v.shootingPoint = RotatePointAroundCenter(p_center, mousePos, 150);
      }

      // Rotate the gun around the player based on mouse position
      angleRad: f32 = math.atan2(mousePos.y - e.position.y, mousePos.x - e.position.x);
      angleDeg: f32 = (180 / math.PI) * angleRad - 90;

      v.rotation = angleDeg;
      
      // Reset Ammo If The Player Dies
      if (currentScene == GameScene.DEATH_MENU || currentScene == GameScene.MAIN_MENU || currentScene == GameScene.END_MENU) {
        v.ammo = 2;
      }

      switch (currentLevel) {
        case .LEVEL1: {if (!enemySpawnedLevel1) {if (v.ammo != 2) {v.ammo = 2;}}} break;
        case .LEVEL2: {if (!enemySpawnedLevel2) {if (v.ammo != 5) {v.ammo = 5;}}} break;
        case .LEVEL3: {if (!enemySpawnedLevel3) {if (v.ammo != 3) {v.ammo = 3;}}} break;
      }

      // Shooting
      if (rl.IsMouseButtonPressed(.LEFT) && v.ammo != 0) {
        bullet := Entity{};
        bullet.hitbox = {0,0,20,20};
        bullet.position = v.shootingPoint;
        bullet.variant = Bullet{false};

        Spawn_Entity(bullet, &bullet);
        v.ammo -= 1;
      }

    } break;
    case Bullet: {
      if (!v.shooted) {
        direction:  rl.Vector2 = mousePos - e.position;
        direction = rl.Vector2Normalize(direction);
        
        e.velocity = direction * 1500;
        v.shooted = true;
      }

      // Border
      if (e.position.x >= 1909)    {e.position.x = 11;}
      else if (e.position.x <= 11) {e.position.x = 1909;}
      if (e.position.y >= 1069)    {e.position.y = 11;}
      else if (e.position.y <= 11) {e.position.y = 1069;}

      // Enemy Collision
      for _,otherEntity in entity_system.entities {
        if (rl.CheckCollisionRecs(e.hitbox, otherEntity.hitbox)) {
          switch q in otherEntity.variant {
            case Enemy: {
              enemyCount -= 1;
              Remove_Entity(otherEntity);
              Remove_Entity(Get_Entity(e.id)^);
            } break;
            case Player: {} break;
            case Bullet: {} break;
            case Gun: {} break;
          }
        }
      }

      // Clear Bullets If The Levels Changed
      switch (currentLevel) {
        case .LEVEL1: {
          if (!enemySpawnedLevel1) {Remove_Entity(Get_Entity(e.id)^);}
        } break;
        case .LEVEL2: {
          if (!enemySpawnedLevel2) {Remove_Entity(Get_Entity(e.id)^);}
        } break;
        case .LEVEL3: {
          if (!enemySpawnedLevel3) {Remove_Entity(Get_Entity(e.id)^);}
        } break;
      }

      // Apply Velocity & Hitbox Position
      e.position += e.velocity * deltaTime;
      e.hitbox.x = e.position.x - 8;
      e.hitbox.y = e.position.y - 10;
    } break;
  }
}

Draw_Entity :: proc(e: ^Entity, showHitbox: bool) {
  switch v in &e.variant {
    case Player: {
      rl.DrawRectangle(i32(e.position.x), i32(e.position.y), 60, 60, rl.BLUE);
      if (showHitbox) {
        rl.DrawRectangleRec(e.hitbox, rl.ColorAlpha(rl.ORANGE, 0.3));
      }
    } break;
    case Enemy: {
      rl.DrawRectangle(i32(e.position.x), i32(e.position.y),60, 60, rl.RED);
      if (showHitbox) {
        rl.DrawRectangleRec(e.hitbox, rl.ColorAlpha(rl.DARKGRAY, .3));
      }
    } break;
    case Gun: {
      rl.DrawRectanglePro({e.position.x, e.position.y, 15, 70}, rl.Vector2(0), v.rotation, rl.DARKPURPLE);
      
      // Shooting Point
      //rl.DrawCircleV(v.shootingPoint, 5, rl.BLUE);

      // Ammo Text
      rl.DrawText(rl.TextFormat("Ammo: %d", v.ammo), 0, 20, 36, rl.RAYWHITE);

    } break;
    case Bullet: {
      rl.DrawCircleV(e.position, 11, rl.Color{255,216,0,255});
      if (showHitbox) {
        rl.DrawRectangleRec(e.hitbox, rl.ColorAlpha(rl.GREEN, 0.3));
      }
    } break;
  }
}

Spawn_Entity :: proc(data: Entity, dataPt: ^Entity) -> Entity_Id {
  entity_system.id_counter += 1;
  id := entity_system.id_counter;
  dataPt.id = id;
  entity_system.entities[id] = data;
  return id;
}

Get_Entity :: proc(id: Entity_Id) -> ^Entity {
  return &entity_system.entities[id] or_else nil;
}

Remove_Entity :: proc(data: Entity) {
  delete_key(&entity_system.entities, data.id);
}

Check_Entity_Collision :: proc(e1, e2: ^Entity) -> bool {
  if (rl.CheckCollisionRecs(e1.hitbox, e2.hitbox)) {return true;}
  else {return false;}
}