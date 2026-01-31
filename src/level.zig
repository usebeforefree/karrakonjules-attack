const std = @import("std");

const rl = @import("raylib");

const m = @import("main.zig");
const Enemy = m.Enemy;
const dtToMs = m.dtToMs;

var state = &m.state;

const player_x = 100;
const player_y = 300;
const player_width = 100;
const player_height = 100;

const enemy_x = 600;
const enemy_y = 300;
const healthbar_height = 50;

// spawn point igraca na 0
// enemy spawn point 100
// clock
// po clocku attack speed.
// enemy se pomera
pub const Level = struct {
    enemies: [10]?Enemy = @splat(null),

    const Self = @This();

    pub fn render(self: *Self) void {
        for (state.fighters.items, 0..) |fighter, idx| {
            _ = fighter; // autofix
            const i: i32 = @intCast(idx);
            const px = player_x - i * 30;
            const py = player_y - i * 30;
            rl.drawRectangle(px + player_width + 10, py, 10, healthbar_height, rl.Color.green);
            rl.drawRectangle(px + player_width + 10, py, 10, healthbar_height / 2, rl.Color.red);
            rl.drawRectangle(px, py, 100, 100, rl.Color.yellow);
        }

        for (self.enemies, 0..) |e, idx| {
            if (e) |enemy| {
                _ = enemy; // autofix
                const i: i32 = @intCast(idx);
                rl.drawRectangle(enemy_x + i * 30, enemy_y - i * 30, 100, 100, rl.Color.blue);
            }
        }
    }
    pub fn update(self: *Self, dt: f64) void {
        for (&self.enemies) |*e| {
            if (e.*) |*enemy| {
                //enemy move
                enemy.x_val -= dt * enemy.speed;

                // enemy attack
                if (enemy.range > enemy.x_val) {
                    enemy.attack_buffer += dtToMs(dt);
                    if (enemy.attack_buffer >= enemy.attack_speed_ms) {
                        enemy.attack_buffer -= enemy.attack_speed_ms;
                        std.log.debug("enemy attack\n", .{});
                        // enemy.attack();
                    }
                }
            }
        }
    }
};
