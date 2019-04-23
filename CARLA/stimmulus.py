#!/usr/bin/env python

# Copyright (c) 2019 Intel Labs
#
# This work is licensed under the terms of the MIT license.
# For a copy, see <https://opensource.org/licenses/MIT>.

# Allows controlling a vehicle with a keyboard. For a simpler and more
# documented example, please take a look at tutorial.py.

"""
Welcome to CARLA manual control with steering wheel Logitech G920.

To drive start by preshing the brake pedal.
Change your wheel_config.ini according to your steering wheel.

To find out the values of your steering wheel use jstest-gtk in Ubuntu.

"""

from __future__ import print_function


# ==============================================================================
# -- find carla module ---------------------------------------------------------
# ==============================================================================


import glob
import os
import sys

import time

try:
    sys.path.append(glob.glob('**/carla-*%d.%d-%s.egg' % (
        sys.version_info.major,
        sys.version_info.minor,
        'win-amd64' if os.name == 'nt' else 'linux-x86_64'))[0])
except IndexError:
    pass


# ==============================================================================
# -- imports -------------------------------------------------------------------
# ==============================================================================


import carla

from carla import ColorConverter as cc


import argparse
import collections
from configparser import ConfigParser
import datetime
import logging
import math
import random
import re
import weakref

from random import randint

try:
    import pygame
    from pygame.locals import KMOD_CTRL
    from pygame.locals import KMOD_SHIFT
    from pygame.locals import K_0
    from pygame.locals import K_9
    from pygame.locals import K_BACKQUOTE
    from pygame.locals import K_BACKSPACE
    from pygame.locals import K_COMMA
    from pygame.locals import K_DOWN
    from pygame.locals import K_ESCAPE
    from pygame.locals import K_F1
    from pygame.locals import K_LEFT
    from pygame.locals import K_PERIOD
    from pygame.locals import K_RIGHT
    from pygame.locals import K_SLASH
    from pygame.locals import K_SPACE
    from pygame.locals import K_TAB
    from pygame.locals import K_UP
    from pygame.locals import K_a
    from pygame.locals import K_c
    from pygame.locals import K_d
    from pygame.locals import K_h
    from pygame.locals import K_m
    from pygame.locals import K_p
    from pygame.locals import K_q
    from pygame.locals import K_r
    from pygame.locals import K_s
    from pygame.locals import K_w
except ImportError:
    raise RuntimeError('cannot import pygame, make sure pygame package is installed')

try:
    import numpy as np
except ImportError:
    raise RuntimeError('cannot import numpy, make sure numpy package is installed')


# ==============================================================================
# -- Global functions ----------------------------------------------------------
# ==============================================================================


def find_weather_presets():
    rgx = re.compile('.+?(?:(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])|$)')
    name = lambda x: ' '.join(m.group(0) for m in rgx.finditer(x))
    presets = [x for x in dir(carla.WeatherParameters) if re.match('[A-Z].+', x)]
    return [(getattr(carla.WeatherParameters, x), name(x)) for x in presets]


def get_actor_display_name(actor, truncate=250):
    name = ' '.join(actor.type_id.replace('_', '.').title().split('.')[1:])
    return (name[:truncate-1] + u'\u2026') if len(name) > truncate else name


# ==============================================================================
# -- World ---------------------------------------------------------------------
# ==============================================================================


class World(object):
    def __init__(self, carla_world, hud, actor_filter):
        self.world = carla_world
        self.hud = hud
        self.player = None
        self.collision_sensor = None
        self.lane_invasion_sensor = None
        self.gnss_sensor = None
        self.camera_manager = None
        self._weather_presets = find_weather_presets()
        self._weather_index = 0
        self._actor_filter = actor_filter
        self.restart()
        self.world.on_tick(hud.on_world_tick)
        
        
        
#        self.my_spawn_point = 0
        
    def restart(self):
        # Keep same camera config if the camera manager exists.
        cam_index = self.camera_manager._index if self.camera_manager is not None else 0
        cam_pos_index = self.camera_manager._transform_index if self.camera_manager is not None else 0
        # Get a random blueprint.
#        blueprint = random.choice(self.world.get_blueprint_library().filter(self._actor_filter))        
        
        #************************Tome solo automoviles de 4 ruedas*************
#        forbidCars = ["police","carlacola","jeep"]
        chosenOne = ["ford"]
        cars = self.world.get_blueprint_library().filter(self._actor_filter)
#        cars = [x for x in cars if int(x.get_attribute('number_of_wheels')) == 4]
        # Remueva los autos que no son adecuados
#        for car in forbidCars:
#            cars = [x for x in cars if car not in x.tags]
		# Escoja un único automóvil
        for car in chosenOne:
            cars = [x for x in cars if car in x.tags]
#        for x in cars:
#            print(x.tags)
        blueprint = random.choice(cars)# elección aleatoria
		
        #**********************************************************************
        
        blueprint.set_attribute('role_name', 'hero')
        if blueprint.has_attribute('color'):
            color = random.choice(blueprint.get_attribute('color').recommended_values)
            blueprint.set_attribute('color', color)
            
        global spawn_pointP
        # Spawn the player.
        if self.player is not None:
            spawn_pointP = self.player.get_transform()
            spawn_pointP.location.z += 2.0
            spawn_pointP.rotation.roll = 0.0
            spawn_pointP.rotation.pitch = 0.0
            self.destroy()
            self.player = self.world.try_spawn_actor(blueprint, spawn_pointP)
            
        while self.player is None:
            spawn_points = self.world.get_map().get_spawn_points()
            spawn_pointP = random.choice(spawn_points) if spawn_points else carla.Transform()
            # Guardar el punto en el que se spawnea para retirarlo de la lista general
#            self.my_spawn_point = spawn_point
            
            self.player = self.world.try_spawn_actor(blueprint, spawn_pointP)
        # Set up the sensors.
        self.collision_sensor = CollisionSensor(self.player, self.hud)
        self.lane_invasion_sensor = LaneInvasionSensor(self.player, self.hud)
        self.gnss_sensor = GnssSensor(self.player)
        self.camera_manager = CameraManager(self.player, self.hud)
        self.camera_manager._transform_index = cam_pos_index
        self.camera_manager.set_sensor(cam_index, notify=False)
        actor_type = get_actor_display_name(self.player)
        self.hud.notification(actor_type)

    def next_weather(self, reverse=False):
        self._weather_index += -1 if reverse else 1
        self._weather_index %= len(self._weather_presets)
        preset = self._weather_presets[self._weather_index]
        self.hud.notification('Weather: %s' % preset[1])
        self.player.get_world().set_weather(preset[0])

    def tick(self, clock):
        self.hud.tick(self, clock)

    def render(self, display):
        self.camera_manager.render(display)
        self.hud.render(display)

    def destroy(self):
        actors = [
            self.camera_manager.sensor,
            self.collision_sensor.sensor,
            self.lane_invasion_sensor.sensor,
            self.gnss_sensor.sensor,
            self.player]
        for actor in actors:
            if actor is not None:
                actor.destroy()


# ==============================================================================
# -- DualControl -----------------------------------------------------------
# ==============================================================================


class DualControl(object):
    def __init__(self, world, start_in_autopilot):
        
        self.reverseFlag = 0
        
        self._autopilot_enabled = start_in_autopilot
        if isinstance(world.player, carla.Vehicle):
            self._control = carla.VehicleControl()
            world.player.set_autopilot(self._autopilot_enabled)
        elif isinstance(world.player, carla.Walker):
            self._control = carla.WalkerControl()
            self._autopilot_enabled = False
            self._rotation = world.player.get_transform().rotation
        else:
            raise NotImplementedError("Actor type not supported")
        self._steer_cache = 0.0
        #world.hud.notification("Press 'H' or '?' for help.", seconds=4.0)

        # initialize steering wheel
        pygame.joystick.init()

        joystick_count = pygame.joystick.get_count()
        if joystick_count > 1:
            raise ValueError("Please Connect Just One Joystick")

        self._joystick = pygame.joystick.Joystick(0)
        self._joystick.init()

        self._parser = ConfigParser()
        self._parser.read('wheel_config.ini')
        self._steer_idx = int(
            self._parser.get('G920 Racing Wheel', 'steering_wheel'))
        self._throttle_idx = int(
            self._parser.get('G920 Racing Wheel', 'throttle'))
        self._brake_idx = int(self._parser.get('G920 Racing Wheel', 'brake'))
        self._reverse_idx = int(self._parser.get('G920 Racing Wheel', 'reverse'))
        self._handbrake_idx = int(
            self._parser.get('G920 Racing Wheel', 'handbrake'))

        # Modificación para los cambios
        self._first_fear_idx = int(self._parser.get('G920 Racing Wheel', 'first_gear'))
        self._second_fear_idx = int(self._parser.get('G920 Racing Wheel', 'second_gear'))
        self._third_fear_idx = int(self._parser.get('G920 Racing Wheel', 'third_gear'))
        self._fourth_fear_idx = int(self._parser.get('G920 Racing Wheel', 'fourth_gear'))
        self._fifth_fear_idx = int(self._parser.get('G920 Racing Wheel', 'fifth_gear'))
        # Habilite la transmisión manual desde un principio
        self._control.manual_gear_shift = True
        
        
    def parse_events(self, world, clock): 
        
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return True
            #=============== BOTONES DEL MANDO ==============
            elif event.type == pygame.JOYBUTTONDOWN:
#                if event.button == 0:
#                    world.restart()
#                elif event.button == 1:
#                    world.hud.toggle_info()
#                elif event.button == 2:
#                    world.camera_manager.toggle_camera()
#                elif event.button == 3:
#                    world.next_weather()
                if event.button == self._reverse_idx:
#                    self._control.gear = 0 if self._control.reverse else -1
                    if self._control.reverse:
                        self._control.gear = 0
                    else:
                        print('reversa')
                        self._control.gear = -1
                        if self.reverseFlag == 0:
                            world.camera_manager.toggle_camera()                      
                        self.reverseFlag = 1
                            
#                    world.camera_manager.toggle_camera()
                            
                    #=== CAMBIO DE CAMARA===
                    
                    

#                elif event.button == 23:
#                    world.camera_manager.next_sensor()
#                elif event.button == self._handbrake_idx:
                    
                
                # Manual Gear Shift
                elif event.button == self._first_fear_idx:
#                    if self.reverseFlag == 1:
#                        world.camera_manager.toggle_camera()
#                        self.reverseFlag = 0
                    self._control.gear = 1
                elif event.button == self._second_fear_idx:
#                    if self.reverseFlag == 1:
#                        world.camera_manager.toggle_camera()
#                        self.reverseFlag = 0
                    self._control.gear = 2
                elif event.button == self._third_fear_idx:
#                    if self.reverseFlag == 1:
#                        world.camera_manager.toggle_camera()
#                        self.reverseFlag = 0
                    self._control.gear = 3
                elif event.button == self._fourth_fear_idx:
#                    if self.reverseFlag == 1:
#                        world.camera_manager.toggle_camera()
#                        self.reverseFlag = 0
                    self._control.gear = 4
                elif event.button == self._fifth_fear_idx:
#                    if self.reverseFlag == 1:
#                        world.camera_manager.toggle_camera()
#                        self.reverseFlag = 0
                    self._control.gear = 5
                
                # MIRAR A LA DERECHA
                elif event.button == 4:
                    world.camera_manager.toggle_camera2()                      
                
                # MIRAR A LA IZQUIERDA
                elif event.button == 5:
                    world.camera_manager.toggle_camera3()                      
                
                # Si hubo otro cambio,  
#                if reverseFlag == 0:
#                    world.camera_manager.toggle_camera()
                    
#                else: 
#                    self._control.gear = 0
            # Si cualquier cambio es liberado, coloque en neutro el auto
            elif event.type == pygame.JOYBUTTONUP:
                self._control.gear = 0
                if self.reverseFlag == 1:
                    world.camera_manager.toggle_camera()
                    self.reverseFlag = 0
                
            
            elif event.type == pygame.KEYUP:
                if self._is_quit_shortcut(event.key):
                    return True
                elif event.key == K_BACKSPACE:
                    world.restart()
                elif event.key == K_F1:
                    world.hud.toggle_info()
                elif event.key == K_h or (event.key == K_SLASH and pygame.key.get_mods() & KMOD_SHIFT):
                    world.hud.help.toggle()
                elif event.key == K_TAB:
                    world.camera_manager.toggle_camera()
                elif event.key == K_c and pygame.key.get_mods() & KMOD_SHIFT:
                    world.next_weather(reverse=True)
                elif event.key == K_c:
                    world.next_weather()
                elif event.key == K_BACKQUOTE:
                    world.camera_manager.next_sensor()
                elif event.key > K_0 and event.key <= K_9:
                    world.camera_manager.set_sensor(event.key - 1 - K_0)
                elif event.key == K_r:
                    world.camera_manager.toggle_recording()
                    
                if isinstance(self._control, carla.VehicleControl):
#                    if event.key == K_q:
#                        self._control.gear = 1 if self._control.reverse else -1

                    if event.key == K_m:
                        self._control.manual_gear_shift = not self._control.manual_gear_shift
                        self._control.gear = world.player.get_control().gear
                        world.hud.notification('%s Transmission' % ('Manual' if self._control.manual_gear_shift else 'Automatic'))

                                
                        
#                    elif self._control.manual_gear_shift:# and event.key == K_COMMA
#                        self._control.gear = max(-1, self._control.gear - 1)
#                    elif self._control.manual_gear_shift:# and event.key == K_PERIOD
#                        self._control.gear = self._control.gear + 1
                    
#                    elif self._control.manual_gear_shift:
                        
#                    elif event.key == K_p:
#                        self._autopilot_enabled = not self._autopilot_enabled
#                        world.player.set_autopilot(self._autopilot_enabled)
#                        world.hud.notification('Autopilot %s' % ('On' if self._autopilot_enabled else 'Off'))
                        
                        
            

        if not self._autopilot_enabled:
            if isinstance(self._control, carla.VehicleControl):
                self._parse_vehicle_keys(pygame.key.get_pressed(), clock.get_time())
                self._parse_vehicle_wheel()
                self._control.reverse = self._control.gear < 0
            elif isinstance(self._control, carla.WalkerControl):
                self._parse_walker_keys(pygame.key.get_pressed(), clock.get_time())
            world.player.apply_control(self._control)

    def _parse_vehicle_keys(self, keys, milliseconds):
        self._control.throttle = 1.0 if keys[K_UP] or keys[K_w] else 0.0
        steer_increment = 5e-4 * milliseconds
        if keys[K_LEFT] or keys[K_a]:
            self._steer_cache -= steer_increment
        elif keys[K_RIGHT] or keys[K_d]:
            self._steer_cache += steer_increment
        else:
            self._steer_cache = 0.0
        self._steer_cache = min(0.7, max(-0.7, self._steer_cache))
        self._control.steer = round(self._steer_cache, 1)
        self._control.brake = 1.0 if keys[K_DOWN] or keys[K_s] else 0.0
        self._control.hand_brake = keys[K_SPACE]

    def _parse_vehicle_wheel(self):
        # si está habilitado
        if self._joystick.get_init():
            numAxes = self._joystick.get_numaxes()
            jsInputs = [float(self._joystick.get_axis(i)) for i in range(numAxes)]
            # print (jsInputs)
            jsButtons = [float(self._joystick.get_button(i)) for i in
                         range(self._joystick.get_numbuttons())]
            
    #        self.buttons = jsButtons
            # Custom function to map range of inputs [1, -1] to outputs [0, 1] i.e 1 from inputs means nothing is pressed
            # For the steering, it seems fine as it is
            K1 = 1.0  # 0.55
            steerCmd = K1 * math.tan(1.1 * jsInputs[self._steer_idx])
    
            K2 = 1.6  # 1.6
            throttleCmd = K2 + (2.05 * math.log10(
                -0.7 * jsInputs[self._throttle_idx] + 1.4) - 1.2) / 0.92
            if throttleCmd <= 0:
                throttleCmd = 0
            elif throttleCmd > 1:
                throttleCmd = 1
    
            brakeCmd = 1.6 + (2.05 * math.log10(
                -0.7 * jsInputs[self._brake_idx] + 1.4) - 1.2) / 0.92
            if brakeCmd <= 0:
                brakeCmd = 0
            elif brakeCmd > 1:
                brakeCmd = 1
    
            self._control.steer = steerCmd
            self._control.brake = brakeCmd
            self._control.throttle = throttleCmd
    
            #toggle = jsButtons[self._reverse_idx]
            self._control.hand_brake = bool(jsButtons[self._handbrake_idx])

        
        


    def _parse_walker_keys(self, keys, milliseconds):
        self._control.speed = 0.0
        if keys[K_DOWN] or keys[K_s]:
            self._control.speed = 0.0
        if keys[K_LEFT] or keys[K_a]:
            self._control.speed = .01
            self._rotation.yaw -= 0.08 * milliseconds
        if keys[K_RIGHT] or keys[K_d]:
            self._control.speed = .01
            self._rotation.yaw += 0.08 * milliseconds
        if keys[K_UP] or keys[K_w]:
            self._control.speed = 5.556 if pygame.key.get_mods() & KMOD_SHIFT else 2.778
        self._control.jump = keys[K_SPACE]
        self._rotation.yaw = round(self._rotation.yaw, 1)
        self._control.direction = self._rotation.get_forward_vector()

    @staticmethod
    def _is_quit_shortcut(key):
        return (key == K_ESCAPE) or (key == K_q and pygame.key.get_mods() & KMOD_CTRL)


# ==============================================================================
# -- HUD -----------------------------------------------------------------------
# ==============================================================================


class HUD(object):
    def __init__(self, width, height):
        self.dim = (width, height)
        font = pygame.font.Font(pygame.font.get_default_font(), 20)
        fonts = [x for x in pygame.font.get_fonts() if 'mono' in x]
        default_font = 'monotypecorsiva'
        mono = default_font if default_font in fonts else fonts[0]
        mono = pygame.font.match_font(mono)
        self._font_mono = pygame.font.Font(mono, 50)
        self._notifications = FadingText(font, (width, 40), (0, height - 40))
        self.help = HelpText(pygame.font.Font(mono, 24), width, height)
        self.server_fps = 0
        self.frame_number = 0
        self.simulation_time = 0
        self._show_info = True
        self._info_text = []
        self._server_clock = pygame.time.Clock()
        # =====TIEMPO DE SIMULACIÓN =========
        self.timer = time.time()

    def on_world_tick(self, timestamp):
        self._server_clock.tick()
        self.server_fps = self._server_clock.get_fps()
        self.frame_number = timestamp.frame_count
        self.simulation_time = timestamp.elapsed_seconds

    def tick(self, world, clock):
        self._notifications.tick(world, clock)
        if not self._show_info:
            return
#        t = world.player.get_transform()
        v = world.player.get_velocity()
        c = world.player.get_control()
#        heading = 'N' if abs(t.rotation.yaw) < 89.5 else ''
#        heading += 'S' if abs(t.rotation.yaw) > 90.5 else ''
#        heading += 'E' if 179.5 > t.rotation.yaw > 0.5 else ''
#        heading += 'W' if -0.5 > t.rotation.yaw > -179.5 else ''
        
#        s6 = pygame.mixer.Sound("6_honking.wav");
#        colhist = world.collision_sensor.get_collision_history()
#        collision = [colhist[x + self.frame_number - 200] for x in range(0, 200)]
#        max_col = max(1.0, max(collision))
#        collision = [x / max_col for x in collision]
#        print(collision[-1])
        
#        vehicles = world.world.get_actors().filter('vehicle.*')
#        traffic_lights = world.world.get_actors().filter('traffic.traffic_light')

        self._info_text = [
#            'Server:  % 16.0f FPS' % self.server_fps,
#            'Client:  % 16.0f FPS' % clock.get_fps(),
#            '',
#            'Vehicle: % 20s' % get_actor_display_name(world.player, truncate=20),
#            'Map:     % 20s' % world.map.name,
            'Tiempo restante: % 12s' % datetime.timedelta(seconds=int(5*60-(time.time()-self.timer) + 2)),#self.simulation_time
#            '',
            '% 15.0f km/h' % (3.6 * math.sqrt(v.x**2 + v.y**2 + v.z**2)),
#            u'Heading:% 16.0f\N{DEGREE SIGN} % 2s' % (t.rotation.yaw, heading),
#            'Location:% 20s' % ('(% 5.1f, % 5.1f)' % (t.location.x, t.location.y)),
#            'GNSS:% 24s' % ('(% 2.6f, % 3.6f)' % (world.gnss_sensor.lat, world.gnss_sensor.lon)),
#            'Height:  % 18.0f m' % t.location.z,
            '']
        if isinstance(c, carla.VehicleControl):
            self._info_text += [
#                ('Acelerador:', c.throttle, 0.0, 1.0),
#                ('Volante:', c.steer, -1.0, 1.0),
#                ('Freno:', c.brake, 0.0, 1.0),
#                ('Reversa:', c.reverse),
##                ('Hand brake:', c.hand_brake),
##                ('Manual:', c.manual_gear_shift),
                'Cambio:        %s' % {-1: 'R', 0: 'N'}.get(c.gear, c.gear)]
#        elif isinstance(c, carla.WalkerControl):
#            self._info_text += [
#                ('Speed:', c.speed, 0.0, 5.556),
#                ('Jump:', c.jump)]
#        self._info_text += [
#            '',
#            'Collision:',
#            collision,
#            '',
#            'Number of vehicles: % 8d' % len(vehicles)]
#        if len(vehicles) > 1:
#            self._info_text += ['Nearby vehicles:']
#            distance = lambda l: math.sqrt((l.x - t.location.x)**2 + (l.y - t.location.y)**2 + (l.z - t.location.z)**2)
#            vehicles = [(distance(x.get_location()), x) for x in vehicles if x.id != world.player.id]
#            for d, vehicle in sorted(vehicles):
#                if d > 200.0:
#                    break
#                vehicle_type = get_actor_display_name(vehicle, truncate=22)
#                self._info_text.append('% 4dm %s' % (d, vehicle_type))
    # == PITIDO DE AUTOS ANTE UN SEMAFORO ===
#        dmax = 40;dmin = 10
#        m = (0-1)/(dmax-dmin);b = -m*(dmax)
#        if len(vehicles) > 1:
#            self._info_text += ['Nearby vehicles:']
#            distance = lambda l: math.sqrt((l.x - t.location.x)**2 + (l.y - t.location.y)**2 + (l.z - t.location.z)**2)
#            vehicles = [(distance(x.get_location()), x) for x in vehicles if x.id != world.player.id]
#            for d, vehicle in sorted(vehicles):
#                if d > dmin and d < dmax:
#                    s6.set_volume(round(m*d+b, 1))
#                    s6.play(1)

    # ==== CONTROL DE SEMAFOROS ====
#        if len(traffic_lights) > 1:
#                distance = lambda l: math.sqrt((l.x - t.location.x)**2 + (l.y - t.location.y)**2 + (l.z - t.location.z)**2)
#                traffic_lights = [(distance(x.get_location()), x) for x in traffic_lights if x.id != world.player.id]
#                for d, traffic_light in sorted(traffic_lights):
#                    flag = 0
#                    if d < 20:
#                        traffic_light.set_green_time(2)
#                        traffic_light.set_red_time(5)
                    
    def toggle_info(self):
        self._show_info = not self._show_info

    def notification(self, text, seconds=2.0):
        self._notifications.set_text(text, seconds=seconds)

    def error(self, text):
        self._notifications.set_text('Error: %s' % text, (255, 0, 0))

    def render(self, display):
        if self._show_info:
            
#            info_surface = pygame.Surface((220, self.dim[1]))
#            info_surface.set_alpha(100)
#            display.blit(info_surface, (0, 0))
            
            v_offset = 600#4
            bar_h_offset = 170#100
            bar_width = 136#106
            
            cont = 0
            for item in self._info_text:
                if v_offset + 18 > self.dim[1]:
                    break
                if isinstance(item, list):
                    if len(item) > 1:
                        points = [(x + 8, v_offset + 8 + (1.0 - y) * 30) for x, y in enumerate(item)]
                        pygame.draw.lines(display, (255, 136, 0), False, points, 2)
                    item = None
                    v_offset += 18
                elif isinstance(item, tuple):
                    if isinstance(item[1], bool):
                        rect = pygame.Rect((bar_h_offset, v_offset + 8), (6, 6))
                        pygame.draw.rect(display, (255, 255, 255), rect, 0 if item[1] else 1)
                    else:
                        rect_border = pygame.Rect((bar_h_offset, v_offset + 8), (bar_width, 6))
                        pygame.draw.rect(display, (255, 255, 255), rect_border, 1)
                        f = (item[1] - item[2]) / (item[3] - item[2])
                        if item[2] < 0.0:
                            rect = pygame.Rect((bar_h_offset + f * (bar_width - 6), v_offset + 8), (6, 6))
                        else:
                            rect = pygame.Rect((bar_h_offset, v_offset + 8), (f * bar_width, 6))
                        pygame.draw.rect(display, (255, 255, 255), rect)
                    item = item[0]
                if item: # At this point has to be a str.
                    # ========= TIEMPO DE SIMULACIÓN Y VELOCIDAD EN PARTES DIFERENTES ========
                    if cont == 0:
                        surface = self._font_mono.render(item, True, (255, 255, 255))
                        display.blit(surface, (10, 10))# 8
                    elif cont == 1:
                        surface = self._font_mono.render(item, True, (255, 255, 255))
                        display.blit(surface, (900, v_offset))# 8
                    else:
                        surface = self._font_mono.render(item, True, (255, 255, 255))
                        display.blit(surface, (900, v_offset+10))# 8
                cont += 1
                v_offset += 18
#        self._notifications.render(display)
        self.help.render(display)


# ==============================================================================
# -- FadingText ----------------------------------------------------------------
# ==============================================================================


class FadingText(object):
    def __init__(self, font, dim, pos):
        self.font = font
        self.dim = dim
        self.pos = pos
        self.seconds_left = 0
        self.surface = pygame.Surface(self.dim)

    def set_text(self, text, color=(255, 255, 255), seconds=2.0):
        text_texture = self.font.render(text, True, color)
        self.surface = pygame.Surface(self.dim)
        self.seconds_left = seconds
        self.surface.fill((0, 0, 0, 0))
        self.surface.blit(text_texture, (10, 11))

    def tick(self, _, clock):
        delta_seconds = 1e-3 * clock.get_time()
        self.seconds_left = max(0.0, self.seconds_left - delta_seconds)
        self.surface.set_alpha(500.0 * self.seconds_left)

    def render(self, display):
        display.blit(self.surface, self.pos)


# ==============================================================================
# -- HelpText ------------------------------------------------------------------
# ==============================================================================


class HelpText(object):
    def __init__(self, font, width, height):
        lines = __doc__.split('\n')
        self.font = font
        self.dim = (680, len(lines) * 22 + 12)
        self.pos = (0.5 * width - 0.5 * self.dim[0], 0.5 * height - 0.5 * self.dim[1])
        self.seconds_left = 0
        self.surface = pygame.Surface(self.dim)
        self.surface.fill((0, 0, 0, 0))
        for n, line in enumerate(lines):
            text_texture = self.font.render(line, True, (255, 255, 255))
            self.surface.blit(text_texture, (22, n * 22))
            self._render = False
        self.surface.set_alpha(220)

    def toggle(self):
        self._render = not self._render

    def render(self, display):
        if self._render:
            display.blit(self.surface, self.pos)


# ==============================================================================
# -- CollisionSensor -----------------------------------------------------------
# ==============================================================================


class CollisionSensor(object):
    def __init__(self, parent_actor, hud):
        self.sensor = None
        self._history = []
        self._parent = parent_actor
        self._hud = hud
        world = self._parent.get_world()
        bp = world.get_blueprint_library().find('sensor.other.collision')
        self.sensor = world.spawn_actor(bp, carla.Transform(), attach_to=self._parent)
        # We need to pass the lambda a weak reference to self to avoid circular
        # reference.
        weak_self = weakref.ref(self)
        self.sensor.listen(lambda event: CollisionSensor._on_collision(weak_self, event))

    def get_collision_history(self):
        history = collections.defaultdict(int)
        for frame, intensity in self._history:
            history[frame] += intensity
        return history

    @staticmethod
    def _on_collision(weak_self, event):
        self = weak_self()
        if not self:
            return
        actor_type = get_actor_display_name(event.other_actor)
        self._hud.notification('Collision with %r' % actor_type)
        impulse = event.normal_impulse
        intensity = math.sqrt(impulse.x**2 + impulse.y**2 + impulse.z**2)
        self._history.append((event.frame_number, intensity))
        if len(self._history) > 4000:
            self._history.pop(0)


# ==============================================================================
# -- LaneInvasionSensor --------------------------------------------------------
# ==============================================================================


class LaneInvasionSensor(object):
    def __init__(self, parent_actor, hud):
        self.sensor = None
        self._parent = parent_actor
        self._hud = hud
        world = self._parent.get_world()
        bp = world.get_blueprint_library().find('sensor.other.lane_detector')
        self.sensor = world.spawn_actor(bp, carla.Transform(), attach_to=self._parent)
        # We need to pass the lambda a weak reference to self to avoid circular
        # reference.
        weak_self = weakref.ref(self)
        self.sensor.listen(lambda event: LaneInvasionSensor._on_invasion(weak_self, event))

    @staticmethod
    def _on_invasion(weak_self, event):
        self = weak_self()
        if not self:
            return
        text = ['%r' % str(x).split()[-1] for x in set(event.crossed_lane_markings)]
        self._hud.notification('Crossed line %s' % ' and '.join(text))

# ==============================================================================
# -- GnssSensor --------------------------------------------------------
# ==============================================================================


class GnssSensor(object):
    def __init__(self, parent_actor):
        self.sensor = None
        self._parent = parent_actor
        self.lat = 0.0
        self.lon = 0.0
        world = self._parent.get_world()
        bp = world.get_blueprint_library().find('sensor.other.gnss')
        self.sensor = world.spawn_actor(bp, carla.Transform(carla.Location(x=1.0, z=2.8)), attach_to=self._parent)
        # We need to pass the lambda a weak reference to self to avoid circular
        # reference.
        weak_self = weakref.ref(self)
        self.sensor.listen(lambda event: GnssSensor._on_gnss_event(weak_self, event))

    @staticmethod
    def _on_gnss_event(weak_self, event):
        self = weak_self()
        if not self:
            return
        self.lat = event.latitude
        self.lon = event.longitude


# ==============================================================================
# -- CameraManager -------------------------------------------------------------
# ==============================================================================


class CameraManager(object):
    def __init__(self, parent_actor, hud):
        self.sensor = None
        self._surface = None
        self._parent = parent_actor
        self._hud = hud
        self._recording = False
        
        self._counterCamera = [0,0,0]
#        self._counterCamera2 = 0
        
        # *************CÁMARA EN PRIMERA PERSONA **************
        self._camera_transforms = [
        carla.Transform(carla.Location(x=-0.25,y=-0.45, z=1.07), carla.Rotation(pitch=5)),
        carla.Transform(carla.Location(x=1.2, z=1.2))]
        # ============== CÁMARA REVERSA ============
        self._camera_transformsR = [
        carla.Transform(carla.Location(x=-0.1,y = -0.47, z=1.1), carla.Rotation(pitch=1,yaw=180)),
        carla.Transform(carla.Location(x=1.2, z=1.2))]
		#******************************************************
        # ============== CÁMARA DERECHA ============
        self._camera_transformsD = [
        carla.Transform(carla.Location(x=-0.1,y = -0.47, z=1.1), carla.Rotation(pitch=1,yaw=90)),
        carla.Transform(carla.Location(x=1.2, z=1.2))]
        # ============== CÁMARA IZQUIERDA ============
        self._camera_transformsI = [
        carla.Transform(carla.Location(x=-0.1,y = -0.47, z=1.1), carla.Rotation(pitch=1,yaw=-90)),
        carla.Transform(carla.Location(x=1.2, z=1.2))]
        

        self._transform_index = 1
        self._sensors = [
            ['sensor.camera.rgb', cc.Raw, 'Camera RGB'],
            ['sensor.camera.depth', cc.Raw, 'Camera Depth (Raw)'],
            ['sensor.camera.depth', cc.Depth, 'Camera Depth (Gray Scale)'],
            ['sensor.camera.depth', cc.LogarithmicDepth, 'Camera Depth (Logarithmic Gray Scale)'],
            ['sensor.camera.semantic_segmentation', cc.Raw, 'Camera Semantic Segmentation (Raw)'],
            ['sensor.camera.semantic_segmentation', cc.CityScapesPalette, 'Camera Semantic Segmentation (CityScapes Palette)'],
            ['sensor.lidar.ray_cast', None, 'Lidar (Ray-Cast)']]
        world = self._parent.get_world()
        bp_library = world.get_blueprint_library()
        for item in self._sensors:
            bp = bp_library.find(item[0])
            if item[0].startswith('sensor.camera'):
                bp.set_attribute('image_size_x', str(hud.dim[0]))
                bp.set_attribute('image_size_y', str(hud.dim[1]))
            elif item[0].startswith('sensor.lidar'):
                bp.set_attribute('range', '5000')
            item.append(bp)
        self._index = None

    def toggle_camera(self):
#        self._transform_index = (self._transform_index + 1) % len(self._camera_transforms)
#        self.sensor.set_transform(self._camera_transforms[self._transform_index])
        if self._counterCamera[0] == 0:
            self.sensor.set_transform(self._camera_transformsR[0])
            self._counterCamera[0] += 1
        else:
            self.sensor.set_transform(self._camera_transforms[0])
            self._counterCamera[0] = 0
            
    def toggle_camera2(self):
#        self._transform_index = (self._transform_index + 1) % len(self._camera_transforms)
#        self.sensor.set_transform(self._camera_transforms[self._transform_index])
        if self._counterCamera[1] == 0:
            self.sensor.set_transform(self._camera_transformsD[0])
            self._counterCamera[1] += 1
        else:
            self.sensor.set_transform(self._camera_transforms[0])
            self._counterCamera[1] = 0

    def toggle_camera3(self):
#        self._transform_index = (self._transform_index + 1) % len(self._camera_transforms)
#        self.sensor.set_transform(self._camera_transforms[self._transform_index])
        if self._counterCamera[2] == 0:
            self.sensor.set_transform(self._camera_transformsI[0])
            self._counterCamera[2] += 1
        else:
            self.sensor.set_transform(self._camera_transforms[0])
            self._counterCamera[2] = 0
            
    def set_sensor(self, index, notify=True):
        index = index % len(self._sensors)
        needs_respawn = True if self._index is None \
            else self._sensors[index][0] != self._sensors[self._index][0]
        if needs_respawn:
            if self.sensor is not None:
                self.sensor.destroy()
                self._surface = None
            self.sensor = self._parent.get_world().spawn_actor(
                self._sensors[index][-1],
                self._camera_transforms[self._transform_index],
                attach_to=self._parent)
            # We need to pass the lambda a weak reference to self to avoid
            # circular reference.
            weak_self = weakref.ref(self)
            self.sensor.listen(lambda image: CameraManager._parse_image(weak_self, image))
        if notify:
            self._hud.notification(self._sensors[index][2])
        self._index = index

    def next_sensor(self):
        self.set_sensor(self._index + 1)

    def toggle_recording(self):
        self._recording = not self._recording
        self._hud.notification('Recording %s' % ('On' if self._recording else 'Off'))

    def render(self, display):
        if self._surface is not None:
            display.blit(self._surface, (0, 0))

    @staticmethod
    def _parse_image(weak_self, image):
        self = weak_self()
        if not self:
            return
        if self._sensors[self._index][0].startswith('sensor.lidar'):
            points = np.frombuffer(image.raw_data, dtype=np.dtype('f4'))
            points = np.reshape(points, (int(points.shape[0]/3), 3))
            lidar_data = np.array(points[:, :2])
            lidar_data *= min(self._hud.dim) / 100.0
            lidar_data += (0.5 * self._hud.dim[0], 0.5 * self._hud.dim[1])
            lidar_data = np.fabs(lidar_data)
            lidar_data = lidar_data.astype(np.int32)
            lidar_data = np.reshape(lidar_data, (-1, 2))
            lidar_img_size = (self._hud.dim[0], self._hud.dim[1], 3)
            lidar_img = np.zeros(lidar_img_size)
            lidar_img[tuple(lidar_data.T)] = (255, 255, 255)
            self._surface = pygame.surfarray.make_surface(lidar_img)
        else:
            image.convert(self._sensors[self._index][1])
            array = np.frombuffer(image.raw_data, dtype=np.dtype("uint8"))
            array = np.reshape(array, (image.height, image.width, 4))
            array = array[:, :, :3]
            array = array[:, :, ::-1]
            self._surface = pygame.surfarray.make_surface(array.swapaxes(0, 1))
        if self._recording:
            image.save_to_disk('_out/%08d' % image.frame_number)


# ==============================================================================
# -- game_loop() ---------------------------------------------------------------
# ==============================================================================


def game_loop(args):
    global spawn_pointP
    
    pygame.mixer.pre_init(44100, -16, 2, 4096)
    pygame.mixer.init()
    pygame.init()
    pygame.font.init()
    world = None

    try:
        start = time.time()
        # ********* Necesario para los actores ()********
        actor_list = []
        #************************************************
        client = carla.Client(args.host, args.port)
        client.set_timeout(2.0)
		# **********PANTALLA NORMAL ***************
        display = pygame.display.set_mode(
            (args.width, args.height),
            pygame.HWSURFACE | pygame.DOUBLEBUF)
        #*******************************************
		
        # **********PANTALLA COMPLETA***************
#        display = pygame.display.set_mode(
#               (args.width, args.height),
#                pygame.FULLSCREEN)
        #*******************************************

        hud = HUD(args.width, args.height)
        world = World(client.get_world(), hud, args.filter)
        
        # ============== SONIDOS ==============
        s00 = pygame.mixer.Sound("0_arranque.wav");
        s00.set_volume(0.25)
        s0 = pygame.mixer.Sound("1_quieto2.wav");
        s0.set_volume(0.15)
        s1 = pygame.mixer.Sound("3_acceleration_slow.wav")
        s1.set_volume(0.05)
        s2 = pygame.mixer.Sound("4_desacceleration.wav")
        s2.set_volume(0.05)
        s3 = pygame.mixer.Sound("2_reverse.wav");
        s3.set_volume(0.05)
        s4 = pygame.mixer.Sound("5_constant2.wav")
        s4.set_volume(0.05)
        # Pitidos
        s6 = pygame.mixer.Sound("6_honking.wav")
        s7 = pygame.mixer.Sound("6_1_honking.wav")
        s_honk = [s6,s7]
        
        # ***************Agregado para vehiculos **************
        blueprints = client.get_world().get_blueprint_library().filter('vehicle.*')
        def try_spawn_random_vehicle_at(transform):
            blueprint = random.choice(blueprints)
            if blueprint.has_attribute('color'):
                color = random.choice(blueprint.get_attribute('color').recommended_values)
                blueprint.set_attribute('color', color)
            blueprint.set_attribute('role_name', 'autopilot')
            vehicle = client.get_world().try_spawn_actor(blueprint, transform)
            if vehicle is not None:
                actor_list.append(vehicle)
                vehicle.set_autopilot()
#                print('spawned %r at %s' % (vehicle.type_id, transform.location))
                return True
            return False

        # @todo Needs to be converted to list to be shuffled.
        spawn_points = list(client.get_world().get_map().get_spawn_points())
        #==== REMUEVA EL SPAWN POINT DE MI AUTO        =====
        spawn_points.remove(spawn_pointP)
        
        random.shuffle(spawn_points)

        print('found %d spawn points.' % len(spawn_points))

        count = args.number_of_vehicles

        for spawn_point in spawn_points:
            if try_spawn_random_vehicle_at(spawn_point):
                count -= 1
            if count <= 0:
                break
            

        while count > 0:
            time.sleep(args.delay)
            if try_spawn_random_vehicle_at(random.choice(spawn_points)):
                count -= 1
        #****************************************************
        
        controller = DualControl(world, args.autopilot)
        clock = pygame.time.Clock()
        
        # === CONFIGURACIÓN DEL TIEMPO DE LOS SEMAFOROS ===
#        traffic_lights = world.world.get_actors().filter('traffic.traffic_light')
        t = world.player.get_transform()
        traffic_lights = world.world.get_actors().filter('traffic.traffic_light')
        if len(traffic_lights) > 1:
                distance = lambda l: math.sqrt((l.x - t.location.x)**2 + (l.y - t.location.y)**2 + (l.z - t.location.z)**2)
                traffic_lights = [(distance(x.get_location()), x) for x in traffic_lights if x.id != world.player.id]
                for d, traffic_light in sorted(traffic_lights):
                    traffic_light.set_green_time(2)
                    traffic_light.set_red_time(5)
        
        
        
        s00.play(0)# SONIDO DE ENCENDIDO
        # Bandera para iniciar el timer
        flag = 0
        v_diff = 0
        cambio_pas = 0# comience idealmente en neutro
        booleanito= True
        # Tiempo de simulación
        t_sim = 2
        
        distance = lambda l: math.sqrt((l.x - t.location.x)**2 + (l.y - t.location.y)**2 + (l.z - t.location.z)**2)
#        distanceX = lambda l: math.sqrt((l.x - t.location.x)**2)
        dmax = 30;dmin = 0
        m = (0-1)/(dmax-dmin);b = -m*(dmax)
        
        while booleanito:
            
            t = world.player.get_transform()
            c = world.player.get_control()
            v = world.player.get_velocity()
            # ===Colisiones===
#            colhist = world.collision_sensor.get_collision_history()
#            collision = [colhist[x + self.frame_number - 200] for x in range(0, 200)]
#            max_col = max(1.0, max(collision))
#            collision = [x / max_col for x in collision]
            
            vehicles = world.world.get_actors().filter('vehicle.*')
            traffic_lights = world.world.get_actors().filter('traffic.traffic_light')

            
            velocidad = 3.6 * math.sqrt(v.x**2 + v.y**2 + v.z**2)
            reversa = c.reverse
            
            
            # Inicie el timer
            if flag == 0:
                ini = time.time()
                v_past = velocidad# velocidad pasada
                flag = 1
            
            # calcule la diferencia de velocidad
            if  int(round(time.time()-ini,1)*10) >= 5:#(int(time.time()-ini))
                flag = 0
                v_diff = velocidad-v_past
#                print('incremento de: ' + str(v_diff) +' km/h')                
                
            if (velocidad < 2 and not(reversa)):
                s1.stop()
                s2.stop()
                s3.stop()
                s4.stop()
                s0.play(-1)
                
            # ACELERACION
            elif (velocidad > 2 and not(reversa) and v_diff > 0 and abs(v_diff) > 2):
                s0.stop()
                s2.stop()
                s3.stop()
                s4.stop()
                s1.play(-1)
            # DESACELERACION
            elif (velocidad > 2 and not(reversa) and v_diff < 0 and abs(v_diff) > 2):
                s0.stop()
                s1.stop()
                s3.stop()
                s4.stop()
                s2.play(-1)
            # CONSTANTE
            elif (velocidad >2 and not(reversa) and abs(v_diff) < 2):
                s0.stop()
                s1.stop()
                s3.stop()
                s2.stop()
                s4.play(-1)
            
            elif (velocidad > 2 and reversa and abs(v_diff) > 2):
                s0.stop()
                s1.stop()
                s2.stop()
                s4.stop()
                s3.play()
                
            # === Si hay un cambio ===
            if (cambio_pas != c.gear and c.gear != 0):
                s1.stop()
                s2.stop()
                s3.stop()
                s4.stop()
                s0.stop()
                s0.play(-1)
            
                # == PITIDO DE AUTOS ANTE UN SEMAFORO ===
            
            
            if len(vehicles) > 1:
#                self._info_text += ['Nearby vehicles:']
                # Mi vehiculo
                myVehicle = [x for x in vehicles if x.id == world.player.id]
                myVehicle = myVehicle[0]
#                print(myVehicle[0])
                if myVehicle.is_at_traffic_light():
                    print('esperando...')
                    
                traffic_lights = [(distance(x.get_location()), x) for x in traffic_lights if x.id != world.player.id]
                vehicles = [(distance(x.get_location()), x) for x in vehicles if x.id != world.player.id]
                
                for d, traffic_light in sorted(traffic_lights):
                    if d < 20:
                        for d2, vehicle in sorted(vehicles):
        #                    print(vehicle)
                            if d2 > dmin and d2 < dmax:
                                ind_aleat = randint(0,1)
                                s_honk[ind_aleat].set_volume(m*d2+b)
                                s_honk[ind_aleat].play(1)
#                                s6.set_volume(m*d2+b)
#                                s6.play(1)
                    
                
            cambio_pas = c.gear
#            print(c.gear)
            
            
            
            clock.tick_busy_loop(60)
            if controller.parse_events(world, clock):
                return
            world.tick(clock)
            world.render(display)
            
            # ========= TERMINE LA SIMULACIÓN ========
            if round(time.time()-start)-1 >= t_sim*60:
                # MENSAJE DE FIN
                default_font = 'monotypecorsiva'
                mono = pygame.font.match_font(default_font)
                font_mono = pygame.font.Font(mono, 60)                
                surface = font_mono.render('Fin de la simulación', True, (255, 255, 255))
                display.blit(surface, (round(args.height/2),round(args.width/2)-300))# 8
                # DESHABILITAR CONTROLES Y DETENER EL AUTO
                
                pygame.joystick.quit()
                # Pasados 5 segundos más, cierre el juego
                if round(time.time()-start)-1 >= t_sim*60+5:
                    booleanito = False
                
            pygame.display.flip()
        
        #Destruir vehiculos generados para que no se acumulen
#        client.apply_batch([carla.command.DestroyActor(x.id) for x in actor_list])

            

    finally:
        #Destruir vehiculos generados para que no se acumulen
        client.apply_batch([carla.command.DestroyActor(x.id) for x in actor_list])
        if world is not None:
            world.destroy()
            


        pygame.quit()


# ==============================================================================
# -- main() --------------------------------------------------------------------
# ==============================================================================


def main():
    argparser = argparse.ArgumentParser(
        description='CARLA Manual Control Client')
    argparser.add_argument(
        '-v', '--verbose',
        action='store_true',
        dest='debug',
        help='print debug information')
    argparser.add_argument(
        '--host',
        metavar='H',
        default='127.0.0.1',
        help='IP of the host server (default: 127.0.0.1)')
    argparser.add_argument(
        '-p', '--port',
        metavar='P',
        default=2000,
        type=int,
        help='TCP port to listen to (default: 2000)')
    #******************Agregado para vehiculos*************
    argparser.add_argument(
        '-n', '--number-of-vehicles',
        metavar='N',
        default=20,
        type=int,
        help='number of vehicles (default: 20)')
    argparser.add_argument(
        '-d', '--delay',
        metavar='D',
        default=2.0,
        type=float,
        help='delay in seconds between spawns (default: 2.0)')
    #****************************************************
    argparser.add_argument(
        '-a', '--autopilot',
        action='store_true',
        help='enable autopilot')
    argparser.add_argument(
        '--res',
        metavar='WIDTHxHEIGHT',
        default='1280x720',
        help='window resolution (default: 1280x720)')
    argparser.add_argument(
        '--filter',
        metavar='PATTERN',
        default='vehicle.*',
        help='actor filter (default: "vehicle.*")')
    args = argparser.parse_args()

    args.width, args.height = [int(x) for x in args.res.split('x')]

    log_level = logging.DEBUG if args.debug else logging.INFO
    logging.basicConfig(format='%(levelname)s: %(message)s', level=log_level)

    logging.info('listening to server %s:%s', args.host, args.port)

    print(__doc__)
    
    

    try:

        game_loop(args)

    except KeyboardInterrupt:
        print('\nCancelled by user. Bye!')


if __name__ == '__main__':

    main()
    
    
'''
A corregir:
    - Carros se spawnean encima o muy cerca mio
    - Remover los botones de cambio de clima y demás en el volante (CHECK)
    - Colocar de manera automática (por defecto), la transmisión manual (CHECK)
    - Tratar de integrar el clutch-> problema desde pygame
    - Limitar la clase de autos que puedo generar para mi (no poli
    ni camiones) (CHECK)
    - Comenzar en "primera persona" (CASI CHECK)
    - Pantalla completa (CHECK)
    
    - Clima dinámico OPCIONAL
    
    
    Maybeee.....
    - Limitar los hud notification
    - Comenzar sin notification
    
    
'''
