const std = @import("std");
const rl = @import("raylib");
const perlin = @import("perlin.zig");
const rg = @import("raygui");
const Level = @import("level.zig").Level;

pub const AnimationEvent = enum {
    none,
    apply_damage,
};

pub const Animation = struct {
    time_elapsed: usize = 0,
    frame_time: usize,
    total_frames: usize,
    is_active: bool = false,
    event: AnimationEvent = .none,

    const Self = @This();

    pub fn init(frame_time: usize, total_frames: usize, event: AnimationEvent) Self {
        return .{
            .frame_time = frame_time,
            .total_frames = total_frames,
            .event = event,
        };
    }

    pub fn start(self: *Self) void {
        self.is_active = true;
        self.time_elapsed = 0;
    }

    pub fn update(self: *Self, dt_ms: usize) AnimationEvent {
        if (!self.is_active) return .none;
        self.time_elapsed += dt_ms;

        if (self.isFinished()) {
            self.is_active = false;
            return self.event;
        }
        return .none;
    }

    pub fn getCurrentFrame(self: *const Self) usize {
        return @min(self.time_elapsed / self.frame_time, self.total_frames - 1);
    }

    pub fn isFinished(self: *const Self) bool {
        return self.time_elapsed >= self.frame_time * self.total_frames;
    }

    pub fn isPlaying(self: *const Self) bool {
        return self.is_active;
    }

    pub fn reset(self: *Self) void {
        self.time_elapsed = 0;
        self.is_active = false;
    }
};

pub const Enemy = struct {
    range: f64,
    max_health: usize,
    health: usize,
    damage: usize,
    speed: f64,
    attack_speed_ms: usize,
    attack_buffer: usize = 0,
    x_val: f64 = 100,

    damage_to_take: usize = 0,
    damage_animation: Animation = Animation.init(100, 8, .apply_damage),

    pub const dmg_frame_time = 100;
    pub const dmg_frames = 8;
};

pub const State = struct {
    const GameState = enum {
        intro,
        chose_fighter,
        level1,
        shop1,
        cutscene1,
        outro,
    };

    fn loadFighterTextures(self: *State) !void {
        inline for (@typeInfo(Fighter).@"enum".fields, 0..) |f, i| {
            const fighter_name = f.name;
            const fighter_texture = try rl.loadTexture(std.fmt.comptimePrint("assets/bodies/{s}.png", .{fighter_name}));

            self.fighter_textures[i] = fighter_texture;
        }
    }
    fn loadDamageTextures(self: *State) !void {
        inline for (0..Enemy.dmg_frames) |i| {
            self.damage_textures[i] = try rl.loadTexture(std.fmt.comptimePrint("assets/dmg_effect/dmg_{d}.png", .{i + 1}));
        }
    }

    fn loadMaskTextures(self: *State) !void {
        inline for (@typeInfo(MaskColour).@"enum".fields, 0..) |m, i| {
            const mask_colour = m.name;
            inline for (0..mask_index_num) |j| {
                const mask_texture = try rl.loadTexture(std.fmt.comptimePrint(
                    "assets/masks/{s}/{s}_{}.png",
                    .{ mask_colour, mask_colour, j + 1 },
                ));
                self.mask_textures[i + j] = mask_texture;
            }
        }
    }

    fn loadKarrakonjulaTextures(self: *State) !void {
        inline for (0..karrakonjules_num) |i| {
            const karrakonjula_texture = try rl.loadTexture(
                std.fmt.comptimePrint("assets/karrakonjules/karrakonjula_{}.png", .{i + 1}),
            );

            self.karrakonjula_textures[i] = karrakonjula_texture;
        }
    }

    const fighter_num = @typeInfo(Fighter).@"enum".fields.len;
    var fighters_buf: [fighter_num]FighterStats = undefined;
    // num of different masks per colour
    const mask_index_num = 4;
    const mask_num = @typeInfo(MaskColour).@"enum".fields.len * mask_index_num;
    var masks_buf: [mask_num]Mask = undefined;

    const karrakonjules_num = 3;

    fighters: std.ArrayList(FighterStats) = .initBuffer(&fighters_buf),
    fighter_textures: [fighter_num]rl.Texture2D = undefined,
    mask_textures: [mask_num]rl.Texture2D = undefined,
    damage_textures: [Enemy.dmg_frames]rl.Texture2D = undefined,
    karrakonjula_textures: [karrakonjules_num]rl.Texture2D = undefined,

    scale: f32 = undefined,

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

    pub fn getFighterStats(self: Fighter, mask: Mask) FighterStats {
        return switch (self) {
            .strong => .{
                .name = @tagName(self),
                .health = 110,
                .max_health = 110,
                .damage = 20,
                .attack_speed_ms = 3000,
                .range = 45,
                .mask = mask,
            },
            .fast => .{
                .name = @tagName(self),
                .health = 100,
                .max_health = 100,
                .damage = 10,
                .attack_speed_ms = 1500,
                .range = 60,
                .mask = mask,
            },
            .smart => .{
                .name = @tagName(self),
                .health = 90,
                .max_health = 90,
                .damage = 10,
                .attack_speed_ms = 2250,
                .range = 75,
                .mask = mask,
            },
        };
    }
};

pub const FighterStats = struct {
    name: []const u8,
    health: usize,
    max_health: usize,
    damage: usize,
    attack_speed_ms: usize,
    attack_time_buffer: usize = 0,
    range: f64,
    mask: Mask,

    damage_to_take: usize = 0,
    damage_animation: Animation = Animation.init(100, 8, .apply_damage),
};

const Mask = struct {
    colour: MaskColour,
    index: u2,
};

const MaskColour = enum {
    red,
    blue,
    green,
    purple,
    yellow,
};

pub fn getRect(tex: rl.Texture2D) rl.Rectangle {
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

fn getScreenX(x: f32) f32 {
    return x * state.scale;
}

fn getScreenY(y: f32) f32 {
    return y * state.scale;
}

pub fn getScaledRect(x: f32, y: f32, w: f32, h: f32, scale: f32) rl.Rectangle {
    return .{
        .x = x * state.scale,
        .y = y * state.scale,
        .width = w * scale * state.scale,
        .height = h * scale * state.scale,
    };
}

fn toF(int: i32) f32 {
    return @floatFromInt(int);
}

// Pivot is at center
pub fn drawSprite(tex: rl.Texture2D, x: f32, y: f32, scale: f32, rot: f32) void {
    const rect = getScaledRect(x, y, toF(tex.width), toF(tex.height), scale);

    const pivot: rl.Vector2 = .{
        .x = toF(tex.width) / 2 * state.scale * scale,
        .y = toF(tex.height) / 2 * state.scale * scale,
    };

    tex.drawPro(getRect(tex), rect, pivot, rot, .white);
}

pub fn dtToMs(dt: f64) usize {
    return @intFromFloat(dt * 1000);
}

pub fn main() anyerror!void {
    const baseWidth = 1280;
    const baseHeight = 720;

    rl.setConfigFlags(.{ .window_resizable = true });

    rl.initWindow(baseWidth, baseHeight, "Karrankonjules attack!");
    defer rl.closeWindow();

    rl.setTargetFPS(60);
    rg.setStyle(.default, .{ .default = .text_size }, 30);

    const menu_texture = try rl.loadTexture("assets/menu_day.png");
    const village = try rl.loadTexture("assets/village.png");
    const sun_rays = try rl.loadTexture("assets/sun_rays.png");
    const sun_play = try rl.loadTexture("assets/play_button.png");
    const cloud = try rl.loadTexture("assets/clouds/cloud_1.png");
    const cloud_2 = try rl.loadTexture("assets/clouds/cloud_2.png");

    try state.loadFighterTextures();
    try state.loadMaskTextures();
    try state.loadDamageTextures();
    try state.loadKarrakonjulaTextures();

    level1.enemies[0] = Enemy{
        .attack_speed_ms = 2000,
        .range = 100,
        .damage = 10,
        .speed = 10,
        .health = 100,
        .max_health = 100,
    };
    level1.enemies[1] = Enemy{
        .attack_speed_ms = 2400,
        .range = 100,
        .damage = 10,
        .speed = 10,
        .health = 100,
        .max_health = 100,
    };
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

    var last_frame_time = rl.getTime();
    while (!rl.windowShouldClose()) {
        const screenw: f32 = @floatFromInt(rl.getScreenWidth());
        const screenh: f32 = @floatFromInt(rl.getScreenHeight());
        const time: f32 = @floatCast(rl.getTime());
        const dt = time - last_frame_time;
        last_frame_time = time;

        const heightRatio: f32 = screenh / @as(f32, @floatFromInt(baseHeight));
        state.scale = heightRatio;

        const horizontal_middle: f32 = screenw / 2 / state.scale;

        std.log.info("screen w: {}, h: {}, ratio: {}", .{ screenw, screenh, heightRatio });

        // INPUT
        if (rl.isKeyPressed(.tab)) {
            debug_mode = !debug_mode;
        }

        switch (state.phase) {
            .level1 => {
                level1.update(dt);
            },
            else => {
                // std.log.debug("Main loop update not implemented for phase: {t}", .{state.phase});
            },
        }
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        const mouse_pos = rl.getMousePosition();

        switch (state.phase) {
            .intro => {
                rl.drawText("Arrow keys to select, ENTER to confirm", 180, 400, 20, .gray);

                const village_noise = perlin.noise(f32, perlin.permutation, .{ .x = time * 0.4, .y = 32.5, .z = 315.3 });
                drawSprite(village, horizontal_middle + village_noise * 20, 550, 1, 0);

                drawSprite(sun_rays, horizontal_middle, 180, 0.7, time * 10);
                drawSprite(sun_play, horizontal_middle, 180, 0.7, 0);

                const cloud_1_noise = perlin.noise(f32, perlin.permutation, .{ .x = time * 0.4, .y = 34.5, .z = 345.3 });
                drawSprite(cloud, horizontal_middle - 400, 100, 0.7, cloud_1_noise * 15);

                const cloud_2_noise = perlin.noise(f32, perlin.permutation, .{ .x = time * 0.4, .y = 134.5, .z = 245.3 });
                drawSprite(cloud_2, horizontal_middle + 400, 100, 0.7, cloud_2_noise * 15);
            },
            .level1 => {
                level1.render();
            },
            .chose_fighter => {
                rl.drawText("Choose Your Fighter", 200, 50, 40, .black);

                inline for (@typeInfo(Fighter).@"enum".fields) |f| {
                    const fighter_name = f.name;
                    const fighter = std.meta.stringToEnum(Fighter, fighter_name).?;
                    const fighter_int = @intFromEnum(fighter);
                    const fighter_texture = state.fighter_textures[fighter_int];

                    const button_rect = rl.Rectangle{
                        .x = 100 + 150 * @as(f32, @floatFromInt(fighter_int)),
                        .y = 150,
                        .width = 120,
                        .height = 120,
                    };

                    const is_hovered = rl.checkCollisionPointRec(mouse_pos, button_rect);
                    const is_clicked = is_hovered and rl.isMouseButtonPressed(.left);

                    rl.drawRectangleRec(button_rect, if (is_hovered) rl.Color.light_gray else rl.Color.gray);
                    rl.drawRectangleLinesEx(button_rect, 2, rl.Color.dark_gray);

                    const img_size: f32 = 100;
                    const img_x = button_rect.x + (button_rect.width - img_size) / 2;
                    const img_y = button_rect.y + 10;

                    fighter_texture.drawPro(getRect(fighter_texture), .{ .x = img_x, .y = img_y, .width = img_size, .height = img_size }, .{ .x = 0, .y = 0 }, 0, .white);

                    const name_width = rl.measureText(fighter_name, 16);
                    rl.drawText(fighter_name, @intFromFloat(button_rect.x + (button_rect.width - @as(f32, @floatFromInt(name_width))) / 2), @intFromFloat(button_rect.y + button_rect.height - 25), 16, .black);

                    if (is_clicked) {
                        // choose mask...
                        const mask = Mask{ .colour = .blue, .index = 0 };
                        state.fighters.appendAssumeCapacity(fighter.getFighterStats(mask));
                        state.nextPhase();
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
