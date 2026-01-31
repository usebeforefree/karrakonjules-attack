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

    const menu_texture = try rl.loadTexture("assets/menu_day.png");

    const rect: rl.Rectangle = .{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(menu_texture.width),
        .height = @floatFromInt(menu_texture.height),
    };

    const rect2: rl.Rectangle = .{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(rl.getScreenWidth()),
        .height = @floatFromInt(rl.getRenderHeight()),
    };

    while (!rl.windowShouldClose()) {
        const time: f32 = @floatCast(rl.getTime());
        const offset_noise = perlin.noise(f32, perlin.permutation, .{ .x = time, .y = 34.5, .z = 345.3 }) * 100;

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        rl.drawTexture(menu_texture, 0, 0, .white);
        rl.drawTexturePro(menu_texture, rect, rect2, .{ .x = 0, .y = 0 }, 0, .white);

        rl.drawText("Karrakonjules attack!", @intFromFloat(offset_noise), 20, 100, .black);
    }
}
