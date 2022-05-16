#ifndef PYBOX2D_DEBUG_DRAW_EXTENDED_DEBUG_DRAW_HXX
#define PYBOX2D_DEBUG_DRAW_EXTENDED_DEBUG_DRAW_HXX

#include "../box2d_wrapper.hpp"

class ExtendedDebugDrawBase : public b2Draw
{
public:
    virtual ~ExtendedDebugDrawBase() {}

    virtual void BeginDraw() = 0 ;
    virtual void EndDraw() = 0;
    virtual bool ReleaseGilWhileDebugDraw() {
        return false;
    }

};

#endif //PYBOX2D_DEBUG_DRAW_EXTENDED_DEBUG_DRAW_HXX