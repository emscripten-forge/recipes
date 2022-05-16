#ifndef PYBOX2D_BOX2D_WRAPPER_HPP
#define PYBOX2D_BOX2D_WRAPPER_HPP

#ifdef PYBOX2D_OLD_BOX2D
    #include <Box2D/Box2D.h>
#else
    #include <box2d/box2d.h>
#endif



#ifdef PYBOX2D_OLD_BOX2D
template<class T>
void set_user_data(T * obj, void * ud)
{
    return obj->SetUserData(ud); 
}

template<class T>
void * get_user_data(T * obj)
{
    return obj->GetUserData();
}
template<class T>
void * get_user_data_from_def(T * def)
{
    return def->userData;
}
template<class T>
void set_user_data_for_def(T * def, void * ud)
{
   def->userData = ud;
}
#else
template<class T>
void  set_user_data(T * obj, void * ud)
{
    obj->GetUserData().pointer = reinterpret_cast<uintptr_t>(ud);
}

template<class T>
void * get_user_data(T * obj)
{
    return reinterpret_cast<void*>(obj->GetUserData().pointer);
}
template<class T>
void * get_user_data_from_def(T * def)
{
   return reinterpret_cast<void*>(def->userData.pointer);
}
template<class T>
void set_user_data_for_def(T * def, void * ud)
{
   def->userData.pointer = reinterpret_cast<uintptr_t>(ud);
}
#endif


#endif //PYBOX2D_BOX2D_WRAPPER_HPP