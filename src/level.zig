const std = @import("std");

const rl = @import("raylib");

const m = @import("main.zig");
const Enemy = m.Enemy;
const dtToMs = m.dtToMs;
const Animation = m.Animation;
const drawSprite = m.drawSprite;
const drawSpriteTint = m.drawSpriteTint;

var state = &m.state;
const State = m.State;

const player_x = 100;
const player_y = 300;
const player_width = 100;
const player_height = 100;

var center_x: f32 = 0;
const enemy_y = 720 - 200;
const healthbar_height = 50;
const PLAYER_OFFSET = 70;

const DAMANGE_ANIMATION_SIZE = 100;

fn renderDamageAnimation(animation: *const Animation, x: f32, y: f32, width: f32, height: f32) void {
    _ = width; // autofix
    _ = height; // autofix
    // TODO scale to width and height
    if (animation.isPlaying()) {
        const frame = animation.getCurrentFrame();
        const dmg_tex = state.damage_textures[frame];
        drawSpriteTint(dmg_tex, x, y, 0.1, 0, rl.Color.red);
        // dmg_tex.drawPro(
        //     m.getRect(dmg_tex),
        //     .{ .x = x, .y = y, .width = width, .height = height },
        //     .{ .x = 0, .y = 0 },
        //     0,
        //     rl.Color.white,
        // );
    }
}

fn drawHealthBar(x: f32, y: f32, width: f32, height: f32, current_health: usize, max_health: usize) void {
    // Draw background bar (empty/dark)
    const scaled_rect = m.getScaledRect(x, y, width, height, 1);
    rl.drawRectangle(
        @intFromFloat(scaled_rect.x),
        @intFromFloat(scaled_rect.y),
        @intFromFloat(scaled_rect.width),
        @intFromFloat(scaled_rect.height),
        rl.Color.dark_gray,
    );

    // Draw current health bar (green)
    if (max_health > 0) {
        const health_ratio: f32 = @as(f32, @floatFromInt(current_health)) / @as(f32, @floatFromInt(max_health));
        const health_height: f32 = height * health_ratio;
        const y_offset = height - health_height;
        const scaled_rect_green = m.getScaledRect(x, y + y_offset, width, health_height, 1);
        rl.drawRectangle(
            @intFromFloat(scaled_rect_green.x),
            @intFromFloat(scaled_rect_green.y),
            @intFromFloat(scaled_rect_green.width),
            @intFromFloat(scaled_rect_green.height),
            rl.Color.green,
        );
    }
}

fn applyDamageEvent(entity: *m.Enemy) void {
    entity.health, const of = @subWithOverflow(entity.health, entity.damage_to_take);
    if (of == 1) {
        entity.health = 0;
    }
    entity.damage_to_take = 0;
}

fn applyDamageEventFighter(entity: *m.FighterStats) void {
    entity.health, const of = @subWithOverflow(entity.health, entity.damage_to_take);
    if (of == 1) {
        entity.health = 0;
        std.debug.print("YOU DIED\n", .{});
    }
    entity.damage_to_take = 0;
}

pub const Level = struct {
    enemies: [10]?Enemy = @splat(null),

    const Self = @This();

    pub fn render(self: *Self) void {
        center_x = state.horizontal_middle;
        // DRAW fighters with healthbars
        for (state.fighters.items, 0..) |fighter, idx| {
            if (fighter.health == 0) continue;
            const i: i32 = @intCast(idx);
            const px: f32 = @floatFromInt(player_x - i * PLAYER_OFFSET);
            const py: f32 = @floatFromInt(player_y - i * PLAYER_OFFSET);

            // rl.drawRectangle(px, py, 100, 100, rl.Color.yellow,);
            drawHealthBar(px + 60, py, 10, healthbar_height, fighter.health, fighter.max_health);
        }
        // Draw all enemy sprites first
        for (self.enemies, 0..) |e, idx| {
            if (e) |enemy| {
                if (enemy.health == 0) {
                    continue;
                }
                const i: f32 = @floatFromInt(idx);

                const px: f32 = center_x + i * PLAYER_OFFSET;
                const py: f32 = enemy_y + i * PLAYER_OFFSET;
                std.log.debug("px {d} py{d}", .{ px, py });
                // rl.drawRectangle(px, py, 100, 100, rl.Color.blue);
                drawSprite(state.karrakonjula_textures[enemy.sprite_id], px, py, 0.4, 0);
                drawHealthBar(px - 60, py, 10, healthbar_height, enemy.health, enemy.max_health);
            }
        }

        // Draw damage animations on top (fighters then enemies)
        for (state.fighters.items, 0..) |fighter, idx| {
            if (fighter.health == 0) continue;

            const i: i32 = @intCast(idx);
            const px = player_x - i * 30;
            const py = player_y - i * 30;
            renderDamageAnimation(&fighter.damage_animation, @floatFromInt(px), @floatFromInt(py), DAMANGE_ANIMATION_SIZE, DAMANGE_ANIMATION_SIZE);
        }

        for (self.enemies, 0..) |e, idx| {
            if (e) |enemy| {
                if (enemy.health == 0) {
                    continue;
                }
                const i: f32 = @floatFromInt(idx);
                renderDamageAnimation(&enemy.damage_animation, center_x + i * 30, enemy_y - i * 30, DAMANGE_ANIMATION_SIZE, DAMANGE_ANIMATION_SIZE);
            }
        }
    }

    pub fn update(self: *Self, dt: f64) void {
        var closest_enemy: ?*Enemy = null;

        for (&self.enemies) |*e| {
            if (e.*) |*enemy| {
                if (enemy.health == 0) {
                    continue;
                }
                // Enemy move
                enemy.x_val -= dt * enemy.speed;

                // Update damage animation and handle events
                const dmg_event = enemy.damage_animation.update(dtToMs(dt));
                if (dmg_event == .apply_damage) {
                    applyDamageEvent(enemy);
                }

                if (closest_enemy == null) {
                    closest_enemy = enemy;
                } else if (enemy.x_val < closest_enemy.?.x_val) {
                    closest_enemy = enemy;
                }

                // Enemy attack
                if (enemy.range > enemy.x_val) {
                    enemy.attack_buffer += dtToMs(dt);
                    if (enemy.attack_buffer >= enemy.attack_speed_ms) {
                        enemy.attack_buffer -= enemy.attack_speed_ms;
                        std.log.debug("enemy attack\n", .{});
                        // Apply damage to first fighter (simple behaviour)
                        if (state.fighters.items.len > 0) {
                            var target = &state.fighters.items[0];
                            target.damage_to_take = enemy.damage;
                            target.damage_animation.start();
                        }
                    }
                }
            }
        }

        for (state.fighters.items) |*f| {
            const dmg_event = f.damage_animation.update(dtToMs(dt));
            if (dmg_event == .apply_damage) {
                applyDamageEventFighter(f);
            }
            if (f.health == 0) continue;

            if (closest_enemy) |enemy| {
                if (f.range >= enemy.x_val) {
                    f.attack_time_buffer += dtToMs(dt);
                    if (f.attack_time_buffer >= f.attack_speed_ms) {
                        f.attack_time_buffer -= f.attack_speed_ms;
                        std.log.debug("Player attack\n", .{});
                        enemy.damage_to_take = f.damage;
                        enemy.damage_animation.start();
                    }
                }
            }
        }
    }
};
