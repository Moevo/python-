import pygame
import random
import math
from enum import Enum

# Initialize pygame
pygame.init()
pygame.mixer.init()

# Game states
class GameState(Enum):
    MENU = 0
    CAMPAIGN = 1
    MULTIPLAYER = 2
    ZOMBIES = 3
    SETTINGS = 4

# Weapon classes
class Weapon:
    def __init__(self, name, damage, fire_rate, ammo_capacity, reload_time):
        self.name = name
        self.damage = damage
        self.fire_rate = fire_rate  # shots per second
        self.ammo_capacity = ammo_capacity
        self.current_ammo = ammo_capacity
        self.reload_time = reload_time  # seconds
        self.last_shot_time = 0
        
    def shoot(self, current_time):
        if current_time - self.last_shot_time >= 1.0 / self.fire_rate and self.current_ammo > 0:
            self.last_shot_time = current_time
            self.current_ammo -= 1
            return True
        return False
    
    def reload(self):
        self.current_ammo = self.ammo_capacity

# Player class
class Player:
    def __init__(self):
        self.health = 100
        self.max_health = 100
        self.position = [0, 0, 0]  # x, y, z
        self.rotation = [0, 0]  # yaw, pitch
        self.weapons = []
        self.current_weapon_index = 0
        self.speed = 5.0
        self.is_sprinting = False
        
    @property
    def current_weapon(self):
        if self.weapons:
            return self.weapons[self.current_weapon_index]
        return None
    
    def take_damage(self, amount):
        self.health -= amount
        if self.health <= 0:
            self.die()
    
    def die(self):
        print("Player died")
        self.health = self.max_health
        # Respawn logic would go here
        
    def move(self, direction, delta_time):
        move_speed = self.speed * 1.5 if self.is_sprinting else self.speed
        move_speed *= delta_time
        
        # Simplified movement - in a real game you'd use vectors and proper rotation
        if direction == "forward":
            self.position[0] += move_speed * math.cos(math.radians(self.rotation[0]))
            self.position[1] += move_speed * math.sin(math.radians(self.rotation[0]))
        elif direction == "backward":
            self.position[0] -= move_speed * math.cos(math.radians(self.rotation[0]))
            self.position[1] -= move_speed * math.sin(math.radians(self.rotation[0]))
        # Add left/right movement here

# Enemy class
class Enemy:
    def __init__(self, enemy_type):
        self.type = enemy_type
        self.health = 50 if enemy_type == "normal" else 100
        self.position = [0, 0, 0]
        self.speed = 2.0
        self.damage = 10
        
    def update(self, player_position):
        # Simple AI: move toward player
        direction = [player_position[0] - self.position[0], 
                     player_position[1] - self.position[1]]
        length = math.sqrt(direction[0]**2 + direction[1]**2)
        if length > 0:
            direction = [direction[0]/length, direction[1]/length]
            self.position[0] += direction[0] * self.speed
            self.position[1] += direction[1] * self.speed
    
    def take_damage(self, amount):
        self.health -= amount
        return self.health <= 0

# Game class
class BlackOpsIIRemastered:
    def __init__(self):
        self.screen_width = 1280
        self.screen_height = 720
        self.screen = pygame.display.set_mode((self.screen_width, self.screen_height))
        pygame.display.set_caption("Black Ops II Remastered Concept")
        
        self.clock = pygame.time.Clock()
        self.running = True
        self.game_state = GameState.MENU
        
        self.player = Player()
        self.enemies = []
        self.bullets = []
        
        # Load weapons
        self.load_weapons()
        
        # Game time
        self.current_time = 0
        
    def load_weapons(self):
        # Basic weapon setup
        assault_rifle = Weapon("AN-94", 35, 10, 30, 2.5)
        smg = Weapon("MP7", 25, 15, 40, 2.0)
        sniper = Weapon("DSR 50", 95, 1.5, 6, 3.0)
        
        self.player.weapons = [assault_rifle, smg, sniper]
    
    def spawn_enemies(self, count):
        for _ in range(count):
            enemy_type = random.choice(["normal", "elite"])
            enemy = Enemy(enemy_type)
            enemy.position = [
                random.randint(-100, 100),
                random.randint(-100, 100),
                0
            ]
            self.enemies.append(enemy)
    
    def handle_input(self):
        keys = pygame.key.get_pressed()
        
        # Movement
        if keys[pygame.K_w]:
            self.player.move("forward", delta_time)
        if keys[pygame.K_s]:
            self.player.move("backward", delta_time)
        # Add other movement keys
        
        # Shooting
        mouse_buttons = pygame.mouse.get_pressed()
        if mouse_buttons[0]:  # Left mouse button
            if self.player.current_weapon.shoot(self.current_time):
                # Create bullet
                pass
        
        # Weapon switching
        if keys[pygame.K_1] and len(self.player.weapons) > 0:
            self.player.current_weapon_index = 0
        if keys[pygame.K_2] and len(self.player.weapons) > 1:
            self.player.current_weapon_index = 1
        # Add more weapon slots
    
    def update(self, delta_time):
        self.current_time += delta_time
        
        # Update enemies
        for enemy in self.enemies[:]:
            enemy.update(self.player.position)
            
            # Simple collision check
            distance = math.sqrt(
                (enemy.position[0] - self.player.position[0])**2 +
                (enemy.position[1] - self.player.position[1])**2
            )
            
            if distance < 2.0:  # Attack range
                self.player.take_damage(enemy.damage * delta_time)
    
    def render(self):
        self.screen.fill((0, 0, 0))  # Clear screen
        
        # Render game based on state
        if self.game_state == GameState.MENU:
            self.render_menu()
        elif self.game_state == GameState.CAMPAIGN:
            self.render_game()
        
        pygame.display.flip()
    
    def render_menu(self):
        # Draw menu UI
        font = pygame.font.SysFont('Arial', 50)
        title = font.render('BLACK OPS II REMASTERED', True, (255, 255, 255))
        self.screen.blit(title, (self.screen_width//2 - title.get_width()//2, 100))
        
        # Menu options
        options = ["CAMPAIGN", "MULTIPLAYER", "ZOMBIES", "SETTINGS", "QUIT"]
        for i, option in enumerate(options):
            text = font.render(option, True, (255, 255, 255))
            self.screen.blit(text, (self.screen_width//2 - text.get_width()//2, 200 + i*70))
    
    def render_game(self):
        # Draw player HUD
        font = pygame.font.SysFont('Arial', 24)
        
        # Health
        health_text = font.render(f'HEALTH: {self.player.health}', True, (255, 0, 0))
        self.screen.blit(health_text, (20, 20))
        
        # Ammo
        if self.player.current_weapon:
            ammo_text = font.render(
                f'AMMO: {self.player.current_weapon.current_ammo}/{self.player.current_weapon.ammo_capacity}',
                True, (255, 255, 255)
            )
            self.screen.blit(ammo_text, (20, 50))
        
        # Weapon name
        if self.player.current_weapon:
            weapon_text = font.render(self.player.current_weapon.name, True, (255, 255, 255))
            self.screen.blit(weapon_text, (self.screen_width - weapon_text.get_width() - 20, 20))
        
        # Draw crosshair
        pygame.draw.line(
            self.screen, (255, 255, 255),
            (self.screen_width//2 - 10, self.screen_height//2),
            (self.screen_width//2 + 10, self.screen_height//2),
            2
        )
        pygame.draw.line(
            self.screen, (255, 255, 255),
            (self.screen_width//2, self.screen_height//2 - 10),
            (self.screen_width//2, self.screen_height//2 + 10),
            2
        )
    
    def run(self):
        while self.running:
            delta_time = self.clock.tick(60) / 1000.0  # Convert to seconds
            
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        if self.game_state == GameState.MENU:
                            self.running = False
                        else:
                            self.game_state = GameState.MENU
            
            if self.game_state != GameState.MENU:
                self.handle_input()
                self.update(delta_time)
            
            self.render()
        
        pygame.quit()

# Run the game
if __name__ == "__main__":
    game = BlackOpsIIRemastered()
    game.spawn_enemies(10)  # For testing
    game.run()