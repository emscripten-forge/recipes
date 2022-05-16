import numpy
import b2d as b2
import pygame
import pygame.locals 
import time

from .pygame_debug_draw import PyGameBatchDebugDraw

class PygameGui(object):
    def __init__(self, testbed_cls, settings=None, testbed_kwargs=None):

        # settings
        resolution = settings.get("resolution", (640,480))
        self.resolution = resolution
        print("resolution",resolution)

        # testworld
        if testbed_kwargs is None:
            testbed_kwargs = dict()
        self.testbed_kwargs = testbed_kwargs
        self.testbed_cls = testbed_cls
        self._testworld  = None

        # flag to stop loop
        self._exit = False

        # surface
        self._surface = None

        # mouse state
        self._last_was_drag = False
        self._last_pos = None

        # steping settings
        self._fps = settings.get("fps", 30) 
        self._dt_s = 1.0 / self._fps

     
    def make_testworld(self):

        if self._testworld is not None:
            self._testworld.say_goodbye_world()
        self._testworld = self.testbed_cls(**self.testbed_kwargs)




    def start_ui(self):

        # make the world
        self.make_testworld()

        # Initialise screen
        pygame.init()
        self._surface = pygame.display.set_mode(self.resolution)
        pygame.display.set_caption(self.testbed_cls.name)


        # debug draw
        # self.debug_draw = PygameDebugDraw(surface=self._surface)
        self.debug_draw = PyGameBatchDebugDraw(surface=self._surface)
        self.debug_draw.flip_y = True
        self.debug_draw.scale = 50.0
        self.debug_draw.translate = (0, self.resolution[1]/2)
        self.debug_draw.append_flags([
            'shape',
            'joint',
            # 'aabb',
            # 'pair',
            'center_of_mass',
            'particle'
        ])
        self._testworld.world.set_debug_draw(self.debug_draw)

        # Event loop
        while 1:
            
            t0 = time.time()
            self._handle_events()

            if self._exit:
                break

            self._step_world()
            self._draw_world()
            t1 = time.time()

            delta = t1 - t0
            if delta < self._dt_s:
                time.sleep(self._dt_s - delta)

     

    def _zoom_in(self):
        self.debug_draw.scale *= 1.25

    def _zoom_out(self):
        self.debug_draw.scale *= 0.75

    def _handle_events(self):

        pressed_keys = pygame.key.get_pressed()
        pressed_mouse_buttons = pygame.mouse.get_pressed()


        ctrl_pressed = pressed_keys[pygame.K_LCTRL] or pressed_keys[pygame.K_RCTRL]

        drag_mode = ctrl_pressed and pressed_mouse_buttons[0]

        if(drag_mode and self._last_was_drag):
            pos = pygame.mouse.get_pos()
            delta = [
                self._last_pos[0] - pos[0],
                self._last_pos[1] - pos[1]
            ]
            translate = self.debug_draw.translate
            self.debug_draw.translate = (
                translate.x - delta[0],
                translate.y - delta[1]
            )
        # 
        self._last_was_drag = drag_mode
        self._last_pos = pygame.mouse.get_pos()

        # TRANSLATION
        if ctrl_pressed:
            d = 0.1
            if pressed_keys[pygame.K_UP]:
                t = self.debug_draw.translate
                self.debug_draw.translate = (t.x, t.y - d)
            elif pressed_keys[pygame.K_DOWN]:
                t = self.debug_draw.translate
                self.debug_draw.translate = (t.x, t.y + d)
            elif pressed_keys[pygame.K_LEFT]:
                t = self.debug_draw.translate
                self.debug_draw.translate = (t.x - d, t.y)
            elif pressed_keys[pygame.K_RIGHT]:
                t = self.debug_draw.translate
                self.debug_draw.translate = (t.x + d, t.y)

        for event in pygame.event.get():
            if event.type == pygame.locals.QUIT:
                self._exit = True
                break

            elif event.type == pygame.MOUSEBUTTONDOWN:
                if event.button == 1:
                    screen_pos = pos = pygame.mouse.get_pos()
                    world_pos = self.debug_draw.screen_to_world(screen_pos)
                    self._testworld.on_mouse_down(world_pos)


                # zoom
                if ctrl_pressed:

                    if event.button == 4:
                        self._zoom_in()
                    elif event.button == 5:
                        self._zoom_out()

            elif event.type == pygame.MOUSEBUTTONUP:
                if event.button == 1:
                    screen_pos = pos = pygame.mouse.get_pos()
                    world_pos = self.debug_draw.screen_to_world(screen_pos)
                    self._testworld.on_mouse_up(world_pos)

            elif event.type == pygame.MOUSEMOTION:
                screen_pos = pos = pygame.mouse.get_pos()
                world_pos = self.debug_draw.screen_to_world(screen_pos)
                self._testworld.on_mouse_move(world_pos)




    def _draw_world(self):
        self._surface.fill((0,0,0))
        self._testworld.world.draw_debug_data()
        pygame.display.update()

    def _step_world(self):
        self._testworld.step(self._dt_s)
