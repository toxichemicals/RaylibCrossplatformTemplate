#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "raylib.h"

int main(void){
	// Make window do window.
	SetConfigFlags(FLAG_VSYNC_HINT | FLAG_MSAA_4X_HINT);
	InitWindow(600, 400, "Such a cool window!");
	SetTargetFPS(60);
	Texture2D hi = LoadTexture("assets/cool.png");
	// Some very cool main func variables
	int tpox = 100;
	int tpoy = 100;

	// Make window actually draw what it is supposed to draw.
	while(!WindowShouldClose()){
		BeginDrawing();
		ClearBackground(RAYWHITE);
		DrawText("Boo!", 10, 70, 20, DARKGRAY);
		DrawLine(0, 0, 100, 100, BLACK);
		// If this rectangle is visible, file loading is failing.
		DrawRectangle(tpox, tpoy, 10, 10, BLACK);
		DrawTexture(hi, tpox, tpoy, WHITE);
		// Movement wizardry
		if(IsKeyDown(KEY_W)){tpoy = tpoy - 10;}
		if(IsKeyDown(KEY_S)){tpoy = tpoy + 10;}
		if(IsKeyDown(KEY_A)){tpox = tpox - 10;}
		if(IsKeyDown(KEY_D)){tpox = tpox + 10;}
		EndDrawing();
	}
}
