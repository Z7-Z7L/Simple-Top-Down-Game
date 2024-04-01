package game

import rl "vendor:raylib"
import "core:fmt"
import "core:math"

SCREEN_WIDTH, SCREEN_HEIGHT :: 1920, 1080;

GameScene :: enum {MAIN_MENU, GAMEPLAY, END_MENU, DEATH_MENU};
GameLevel :: enum {LEVEL1, LEVEL2, LEVEL3};

entity_system: Entity_System;
entityVariant: Entity_Variant;

// Scene Manager
currentScene: GameScene = .MAIN_MENU;
currentLevel: GameLevel = .LEVEL1;

enemyCount: i32;

enemySpawnedLevel1: bool = false;
enemySpawnedLevel2: bool = false;
enemySpawnedLevel3: bool = false;

main :: proc() {
  // Initialization
  rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Game");

  rl.SetTargetFPS(60);

  rl.DisableCursor();

  icon: rl.Image = rl.LoadImage("Icon.png")
  rl.SetWindowIcon(icon);

  monitorWidth  :i32 = 1920
  monitorHeight :i32 = 1080

  if (!rl.IsWindowFullscreen()) {
    rl.SetWindowSize(monitorWidth, monitorHeight);
  }

  // Player & Gun
  player := Entity{};
  player.hitbox = {0,0,60,60};
  player.position = {250, 250};
  player.variant = Player{380, rl.Vector2(0)};
  
  gun := Entity{};
  gun.variant = Gun{2, 0, rl.Vector2(0)};

  Spawn_Entity(player, &player);
  Spawn_Entity(gun, &gun);

  // Cursor
  cursorColor := rl.RAYWHITE;

  /*** Game Loop ***/
  for (!rl.WindowShouldClose()) {
    /*** Update ***/
    // Delta Time
    deltaTime := rl.GetFrameTime();
    // Mouse Position
    mousePos := rl.GetMousePosition();
    
    // Toggle FullScreen
    if (rl.IsKeyPressed(.TAB)) {
      rl.ToggleFullscreen();
    }

    switch (currentScene) {
      case .MAIN_MENU: {
        if (rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.ENTER)) {
          currentScene = .GAMEPLAY;
        }
      } break;
      case .GAMEPLAY: {
        // Change Level
        switch (currentLevel) {
          case .LEVEL1: {
            if (!enemySpawnedLevel1) {
              for i := 0; i < 2; i += 1 {
                randPos: rl.Vector2 = {f32(rl.GetRandomValue(280, 1860)), f32(rl.GetRandomValue(300, 1020))};
                
                enemy := Entity{};
                enemy.variant = Enemy{60};
                
                if (Check_Entity_Collision(&enemy, &player)) {
                  randPos2: rl.Vector2 = {f32(rl.GetRandomValue(280, 1860)), f32(rl.GetRandomValue(280, 1020))};
                  enemy.position = randPos2;
                }
                else {
                  enemy.position = randPos;
                }

                enemy.hitbox = {0,0,60,60};
                
                enemyCount += 1;
                Spawn_Entity(enemy, &enemy);
              }
              
              enemySpawnedLevel1 = true;
            }
            
            if (enemyCount == 0) {
              currentLevel = GameLevel.LEVEL2;
            }

          } break;
          case .LEVEL2: {
            if (!enemySpawnedLevel2) {      
              for i := 0; i < 5; i += 1 {
                randPos: rl.Vector2 = {f32(rl.GetRandomValue(60, 1860)), f32(rl.GetRandomValue(60, 1020))};
              
                enemy := Entity{};
                enemy.variant = Enemy{60};
                enemy.hitbox = {0,0,60,60};

                if (Check_Entity_Collision(&enemy, &player)) {
                  randPos2: rl.Vector2 = {f32(rl.GetRandomValue(280, 1860)), f32(rl.GetRandomValue(280, 1020))};
                  enemy.position = randPos2;
                }
                else {
                  enemy.position = randPos;
                }
  
                enemyCount += 1;
                Spawn_Entity(enemy, &enemy);
              }
              
              enemySpawnedLevel2 = true;
            }

            if (enemyCount == 0) {
              currentLevel = GameLevel.LEVEL3;
            }
          } break;
          case .LEVEL3: {
            if (!enemySpawnedLevel3) {
              for i := 0; i < 3; i += 1 {
                randPos: rl.Vector2 = {f32(rl.GetRandomValue(60, 1860)), f32(rl.GetRandomValue(60, 1020))};
              
                enemy := Entity{};
                enemy.variant = Enemy{60};
                enemy.hitbox = {0,0,60,60};

                if (Check_Entity_Collision(&enemy, &player)) {
                  randPos2: rl.Vector2 = {f32(rl.GetRandomValue(280, 1860)), f32(rl.GetRandomValue(280, 1020))};
                  enemy.position = randPos2;
                }
                else {
                  enemy.position = randPos;
                }
  
                enemyCount += 1;
                Spawn_Entity(enemy, &enemy);
              }
              
              enemySpawnedLevel3 = true;
            }

            if (enemyCount == 0) {
              enemySpawnedLevel1, enemySpawnedLevel2, enemySpawnedLevel3 = false, false, false;
              currentScene = GameScene.END_MENU;
              currentLevel = GameLevel.LEVEL1;
            }
          } break;
        }

        // Entities
        for i in entity_system.entities {
          Update_Entity(Get_Entity(i), deltaTime);
        }
        
      } break;
      case .END_MENU: {
        if (rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.ENTER)) {
          currentScene = .MAIN_MENU;
        }
      } break;
      case .DEATH_MENU: {
        enemySpawnedLevel1, enemySpawnedLevel2, enemySpawnedLevel3 = false, false, false;
        for _,otherEntity in entity_system.entities {
          switch enevar in otherEntity.variant {
            case Enemy: {
              Remove_Entity(otherEntity);
              enemyCount = 0;
            } break;
            case Player: {} break;
            case Gun: {} break;
            case Bullet: {Remove_Entity(otherEntity)} break;
          }
        }
        if (rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.ENTER)) {
          currentScene = .MAIN_MENU;
        }
      } break;
    }

    /*** Update ***/

    /*** Draw ***/
    rl.BeginDrawing();
      switch (currentScene) {
        case .MAIN_MENU: {
          rl.ClearBackground(rl.RAYWHITE);
          
          cursorColor = rl.GRAY;

          rl.DrawText("PRESS ENTER OR SPACE TO START GAME", monitorWidth/2 - 650, monitorHeight/2 - 29, 60, rl.LIGHTGRAY);

        } break;
        case .GAMEPLAY: {
          rl.ClearBackground(rl.Color{40,40,40, 255});
          
          cursorColor = rl.RAYWHITE;
          
          // Level Text
          switch (currentLevel) {
            case .LEVEL1: {
              rl.DrawText("ROUND 1", 710, 500, 120, rl.Color{80,80,80, 255});
            } break;
            case .LEVEL2: {
              rl.DrawText("ROUND 2", 710, 500, 120, rl.Color{80,80,80, 255});
            }
            case .LEVEL3: {
              rl.DrawText("ROUND 3", 710, 500, 120, rl.Color{80,80,80, 255});
            } break;
          }

          // Entities
          for i in entity_system.entities {
            Draw_Entity(Get_Entity(i), false);
          }

          
        } break;
        case .END_MENU: {
          rl.ClearBackground(rl.RAYWHITE);
          
          cursorColor = rl.GRAY;

          rl.DrawText("PRESS ENTER OR SPACE TO RESTART GAME", monitorWidth/2 - 690, monitorHeight/2 - 29, 60, rl.LIGHTGRAY);
        } break;
        case .DEATH_MENU: {
          rl.ClearBackground(rl.RAYWHITE);
          
          cursorColor = rl.GRAY;

          rl.DrawText("YOU DEAD!", monitorWidth/2 - 400, monitorHeight/2 - 190, 150, rl.LIGHTGRAY);
          rl.DrawText("PRESS ENTER OR SPACE TO GO TO THE MAIN MENU", monitorWidth/2 - 820, monitorHeight/2 - 29, 60, rl.LIGHTGRAY);
        } break;
      }

      // Cursor
      rl.DrawCircleV(mousePos, 7, cursorColor);

      // Draw FPS & Text
      rl.DrawFPS(0, 0);

    rl.EndDrawing();

    /*** Draw ***/
  }
  /*** Game Loop ***/

  // Clear All Entities
  defer delete_map(entity_system.entities);

  // Close the window
  rl.CloseWindow();
}

RotatePointAroundCenter :: proc(center, mousePos: rl.Vector2, distance: f32) -> rl.Vector2 {
  angle: f32 = math.atan2(mousePos.y - center.y, mousePos.x - center.x);

  newX: f32 = center.x + distance * math.cos(angle);
  newY: f32 = center.y + distance * math.sin(angle);

  return rl.Vector2{newX, newY};
}