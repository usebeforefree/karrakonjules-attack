const std = @import("std");
const rl = @import("raylib");
const perlin = @import("perlin.zig");
const rg = @import("raygui");
const Level = @import("level.zig").Level;

// atck range, atack speed, speed
pub const Enemy = struct {
    fireRate: u32,
    range: u32,
};

pub const State = struct {
    const GameState = enum {
        intro,
        chose_fighter,
        shop1,
        level1,
        cutscene1,
        outro,
    };

    var fighters_buf: [10]FighterStats = undefined;
    fighters: std.ArrayList(FighterStats) = .initBuffer(&fighters_buf),

    phase: GameState = .intro,
    pub fn nextPhase(self: *State) void {
        self.phase = std.meta.intToEnum(GameState, @intFromEnum(self.phase) + 1) catch self.phase;
    }
};

pub var state: State = .{};
pub var debug_mode: bool = true;
pub var level1 = Level{};

const Fighter = enum {
    strong,
    fast,
    smart,

    pub fn getFighterStats(self: Fighter) FighterStats {
        return switch (self) {
            .strong => .{
                .name = @tagName(self),
                .health = 110,
                .damage = 20,
                .attack_speed_ms = 3000,
                .range = 45,
            },
            .fast => .{
                .name = @tagName(self),
                .health = 100,
                .damage = 10,
                .attack_speed_ms = 1500,
                .range = 60,
            },
            .smart => .{
                .name = @tagName(self),
                .health = 90,
                .damage = 10,
                .attack_speed_ms = 2250,
                .range = 75,
            },
        };
    }
};

const FighterStats = struct {
    name: []const u8,
    health: usize,
    damage: usize,
    attack_speed_ms: usize,
    range: usize,
};

fn getRect(tex: rl.Texture2D) rl.Rectangle {
    return .{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(tex.width),
        .height = @floatFromInt(tex.height),
    };
}

fn drawFullscreenCentered(tex: rl.Texture2D) void {
    const sw: f32 = @floatFromInt(rl.getScreenWidth());
    const sh: f32 = @floatFromInt(rl.getScreenHeight());

    const aspect = sh / sw;
    _ = aspect;
    const tw: f32 = @floatFromInt(tex.width);
    const th: f32 = @floatFromInt(tex.height);

    const ratio = sh / th;

    const center = sw / 2;

    const target_width = tw * ratio;

    const screen_rect: rl.Rectangle = .{
        .x = center - target_width / 2,
        .y = 0,
        .width = target_width,
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
    rg.setStyle(.default, .{ .default = .text_size }, 30);

    const menu_texture = try rl.loadTexture("assets/menu_day.png");

    level1.enemies[0] = Enemy{ .fireRate = 10, .range = 5 };
    level1.enemies[1] = Enemy{ .fireRate = 10, .range = 5 };
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

        // INPUT
        if (rl.isKeyPressed(.tab)) {
            debug_mode = !debug_mode;
        }

        switch (state.phase) {
            .level1 => {
                level1.update(0.0);
            },
            else => {
                // std.log.debug("Main loop update not implemented for phase: {t}", .{state.phase});
            },
        }
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        switch (state.phase) {
            .intro => {
                rl.drawText("Karrakonjules attack!", @intFromFloat(offset_noise), 20, 100, .black);

                rl.drawText("Arrow keys to select, ENTER to confirm", 180, 400, 20, .gray);
            },
            .level1 => {
                level1.render();
            },
            .chose_fighter => {
                drawFullscreenCentered(menu_texture);

                rl.drawText("Choose Your Fighter", 200, 50, 40, .black);

                inline for (@typeInfo(Fighter).@"enum".fields, 0..) |fighter, i| {
                    if (rg.button(
                        .{
                            .height = 100,
                            .width = 100,
                            .x = 100 + 100 * i,
                            .y = 100,
                        },
                        fighter.name,
                    )) {
                        state.fighters.appendAssumeCapacity(std.meta.stringToEnum(Fighter, fighter.name).?.getFighterStats());
                        break;
                    }
                }
            },
            else => {
                std.log.debug("Main loop render not implemented for phase: {t}", .{state.phase});
            },
        }

        if (debug_mode) {
            if (rg.button(.{ .height = 35, .width = 200, .x = 10, .y = 10 }, "Next phase")) {
                state.nextPhase();
            }
            _ = rg.label(.{ .height = 75, .width = 100, .x = 10, .y = 30 }, @tagName(state.phase));
        }
    }
}
