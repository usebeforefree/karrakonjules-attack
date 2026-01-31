const std = @import("std");
const rl = @import("raylib");

const State = struct {
    const GameState = enum {
        intro,
        game,
        outro,
    };

    var phase: GameState = .intro;
};

var state: State = .{};

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "Karrankonjules attack!");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        rl.drawText("Karrakonjules attack!", 20, 20, 100, .black);
    }
}
