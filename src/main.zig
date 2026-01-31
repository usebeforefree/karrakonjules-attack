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

fn getRect(tex: rl.Texture2D) rl.Rectangle {
    return .{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(tex.width),
        .height = @floatFromInt(tex.height),
    };
}

fn drawScaled(tex: rl.Texture2D) void {
    const sw: f32 = @floatFromInt(rl.getScreenWidth());
    const sh: f32 = @floatFromInt(rl.getScreenHeight());

    const aspect = sh / sw;
    _ = aspect;
    const tw: f32 = @floatFromInt(tex.width);
    const th: f32 = @floatFromInt(tex.height);

    const ratio = sh / th;

    const screen_rect: rl.Rectangle = .{
        .x = 0,
        .y = 0,
        .width = tw * ratio,
        .height = th * ratio,
    };

    tex.drawPro(getRect(tex), screen_rect, .{ .x = 0, .y = 0 }, 0, .white);
}

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 450;

    rl.setConfigFlags(.{ .window_resizable = true });

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

    _ = rect;

    const screen_rect: rl.Rectangle = .{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(rl.getScreenWidth()),
        .height = @floatFromInt(rl.getRenderHeight()),
    };

    _ = screen_rect;

    while (!rl.windowShouldClose()) {
        const time: f32 = @floatCast(rl.getTime());
        const offset_noise = perlin.noise(f32, perlin.permutation, .{ .x = time, .y = 34.5, .z = 345.3 }) * 100;

        //const target = try rl.loadRenderTexture(1024, 786);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);
        //rl.drawTexture(menu_texture, 0, 0, .white);
        //rl.drawTexturePro(menu_texture, rect, rect2, .{ .x = 0, .y = 0 }, 0, .white);

        drawScaled(menu_texture);

        rl.drawText("Karrakonjules attack!", @intFromFloat(offset_noise), 20, 100, .black);
    }
}
