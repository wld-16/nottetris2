//
// Created by wld on 05.10.26.
//

#ifndef NOTTETRIS2_VITA2D_DEBUG_DRAW_H
#define NOTTETRIS2_VITA2D_DEBUG_DRAW_H
#include <box2d/types.h>


class vita2d_debug_draw : public b2DebugDraw
{
public:
    static void vita2dDrawPolygonFcn( const b2Vec2* vertices, int vertexCount, b2HexColor color, void* context );
    static void vita2dDrawSolidPolygonFcn( b2Transform transform, const b2Vec2* vertices, int vertexCount, float radius, b2HexColor color,
                                void* context );
    void* vita2dDrawCircleFcn( b2Vec2 center, float radius, b2HexColor color, void* context );
    void* vita2dDrawSolidCircleFcn( b2Transform transform, float radius, b2HexColor color, void* context );
    void* vita2dDrawSolidCapsuleFcn( b2Vec2 p1, b2Vec2 p2, float radius, b2HexColor color, void* context );
    void* vita2dDrawSegmentFcn( b2Vec2 p1, b2Vec2 p2, b2HexColor color, void* context );
    void* vita2dDrawTransformFcn( b2Transform transform, void* context );
    void* vita2dDrawPointFcn( b2Vec2 p, float size, b2HexColor color, void* context );
    void* vita2dDrawStringFcn( b2Vec2 p, const char* s, b2HexColor color, void* context );
};


#endif //NOTTETRIS2_VITA2D_DEBUG_DRAW_H
