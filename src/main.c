#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "raylib.h"

// Defined constant for player movement speed (600 pixels per second)
// 600 px/sec is 10 pixels per frame at 60 FPS.
#define MOVE_SPEED 600.0f
// Define player size constants for clamping
#define PLAYER_WIDTH 100
#define PLAYER_HEIGHT 100

int main(void){

	// Make window do window.
	InitWindow(800, 600, "Such a cool window!");
	SetTargetFPS(60);
    
	// --- CONTROL FLAGS ---
	int fpscap = 1;
    // Flag to control movement clock (Delta Time). 1 = On (constant speed), 0 = Off (light speed/CPU-bound)
    int clock_on = 1; 

	Texture2D hi = LoadTexture("assets/cool.png");
    
	// Some very cool main func variables
	float ppox = 100.0f; // Use float for smooth delta time movement
	float ppoy = 100.0f; // Use float for smooth delta time movement
    
	// Make window actually draw what it is supposed to draw.
	while(!WindowShouldClose()){
        
        // --- 1. Get Delta Time ---
        // GetFrameTime() returns the time in seconds since the last frame was drawn.
        float dt = GetFrameTime();
        
        // --- 2. Input Handling ---
        
		if(IsKeyPressed(KEY_V)){
            if(fpscap == 1){
                printf("FPS Cap off.\n");
                fpscap = 0;
                SetTargetFPS(0);
            } else if(fpscap == 0){
                printf("FPS Cap on.\n");
                fpscap = 1;
                SetTargetFPS(60);
            }
		}

        // Toggle the movement clock (Delta Time) on/off
        if(IsKeyPressed(KEY_C)){
            clock_on = !clock_on;
            if(clock_on) {
                printf("Movement Clock ON (Speed is constant).\n");
            } else {
                printf("Movement Clock OFF (Speed is CPU/FPS bound).\n");
            }
        }
        
		// --- 3. Movement Wizardry ---
        
        // Determine the speed multiplier: MOVE_SPEED * dt if clock is on, otherwise a large fixed value (e.g., 10.0f)
        float speed_multiplier;
        if (clock_on) {
            // Clock ON: Consistent movement (600 pixels/second)
            speed_multiplier = MOVE_SPEED * dt;
        } else {
            // Clock OFF: CPU-bound movement (fixed 10 pixels per frame)
            speed_multiplier = 10.0f; 
        }

		if(IsKeyDown(KEY_W)){ppoy -= speed_multiplier;}
		if(IsKeyDown(KEY_S)){ppoy += speed_multiplier;}
		if(IsKeyDown(KEY_A)){ppox -= speed_multiplier;}
		if(IsKeyDown(KEY_D)){ppox += speed_multiplier;}
        
		// --- 4. Bounds Wizardry ---
        
		// Prevent moving past x (Max X is 800 - 100 = 700)
		if (ppox < 0) {
		    ppox = 0;
		} else if (ppox > (800 - PLAYER_WIDTH)) {
		    ppox = (800 - PLAYER_WIDTH);
		}

		// Prevent moving past y (Max Y is 600 - 100 = 500)
		if (ppoy < 0) {
		    ppoy = 0;
		} else if (ppoy > (600 - PLAYER_HEIGHT)) {
		    ppoy = (600 - PLAYER_HEIGHT);
		}


		// --- 5. Drawing ---
        
		BeginDrawing();
		ClearBackground(RAYWHITE);
		
		DrawFPS(0, 0);
		
        // Draw instructions for the new clock feature
        const char *clock_status = clock_on ? "ON" : "OFF";
        DrawText(TextFormat("Movement Clock (C key): %s", clock_status), 10, 30, 20, clock_on ? DARKGREEN : RED);

		DrawText("Click V to disable framecapping! (Should not affect web)", 10, 70, 20, DARKGRAY);
		DrawText("On Native, will make player instantly go the speed of light.", 10, 100, 15, DARKGRAY);
		
		DrawLine(0, 550, 100, 500, BLACK);
		
		// Draw the player (using float position, cast to int for drawing)
		DrawRectangle((int)ppox, (int)ppoy, PLAYER_WIDTH, PLAYER_HEIGHT, BLACK);
		DrawTexture(hi, (int)ppox, (int)ppoy, WHITE);

		EndDrawing();
	}
    
    UnloadTexture(hi);
    CloseWindow();
    
    return 0;
}