const std = @import("std");
const rl = @import("raylib");
const perlin = @import("perlin.zig");

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
        const time: f32 = @floatCast(rl.getTime());
        const offset_noise = perlin.noise(f32, perlin.permutation, .{ .x = time, .y = 34.5, .z = 345.3 }) * 100;

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        rl.drawText("Karrakonjules attack!", @intFromFloat(offset_noise), 20, 100, .black);
    }
}
