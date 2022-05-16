class NoGui(object):
    def __init__(self, testbed_cls, settings, testbed_kwargs=None):
        
        self.testbed_cls = testbed_cls
        self.testbed_kwargs = testbed_kwargs
        self._testworld = None

        self._dt = settings.get('dt', 1.0/40.0)
        self._t = settings.get('t',10)
        self._n = int(0.5 + self._t / self._dt)
    

    # run the world for a limited amount of steps
    def start_ui(self):
        
        self._testworld = self.testbed_cls(**self.testbed_kwargs)
        
        for i in range(self._n):
            self._testworld.step(self._dt)
