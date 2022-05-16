
def add_user_data_api(cls):

    @property
    def user_data(self):
        if self.has_object_user_data:
            return self._get_object_user_data()
        else:
            return None

    cls.user_data = user_data

    @user_data.setter
    def user_data(self, ud):
        if ud is None:
            self._clear_object_user_data()
        else:
            self._set_object_user_data(ud)
    cls.user_data = user_data
