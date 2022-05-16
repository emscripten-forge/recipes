from . _b2d import *


class QueryCallback(QueryCallbackCaller):

    def __init__(self):
        super(QueryCallback,self).__init__(self)

    def report_fixture(self, fixture):
        raise NotImplementedError 
    def report_particle(self, particleSystem, index):
        return False
    def should_query_particle_system(self, particleSystem):
        return False
