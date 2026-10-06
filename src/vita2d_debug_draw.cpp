//
// Created by wld on 05.10.26.
//

#include "vita2d_debug_draw.h"

#include <vita2d.h>
#include <box2d/math_functions.h>

// b2HexColor is an enum holding 0xRRGGBB; vita2d expects RGBA8 (0xRRGGBBAA).
static unsigned int to_rgba8(b2HexColor color)
{
    return static_cast<unsigned int>(color) | 0xFF000000u;
}

// Draw each edge of the polygon as a line using vita2d_draw_line, which
// correctly sets sceGxmSetFrontPolygonMode to LINE and resets it afterward.
// vita2d_draw_array does NOT set the front polygon mode, so passing
// SCE_GXM_PRIMITIVE_LINES with the default TRIANGLE_FILL mode produces
// nothing visible.
// context points to a float (physicsscale) that converts Box2D world
// coordinates to screen pixels.
static void drawPolygonOutline(const b2Vec2* worldVertices, int vertexCount, b2HexColor color, void* context)
{
    if (vertexCount < 2)
        return;

    float scale = 1.0f;
    if (context)
        scale = *static_cast<float*>(context);

    unsigned int rgba = to_rgba8(color);
    for (int i = 0; i < vertexCount; i++)
    {
        int j = (i + 1) % vertexCount;
        vita2d_draw_line(worldVertices[i].x * scale, worldVertices[i].y * scale,
                        worldVertices[j].x * scale, worldVertices[j].y * scale, rgba);
    }
}

void vita2d_debug_draw::vita2dDrawPolygonFcn( const b2Vec2* vertices, int vertexCount, b2HexColor color, void* context )
{
    // DrawPolygonFcn receives vertices already in world space.
    drawPolygonOutline(vertices, vertexCount, color, context);
}

/// Draw a solid closed polygon provided in CCW order.
void vita2d_debug_draw::vita2dDrawSolidPolygonFcn( b2Transform transform, const b2Vec2* vertices, int vertexCount, float radius, b2HexColor color,
                            void* context )
{
    // DrawSolidPolygonFcn receives vertices in the body's local space and a
    // transform to convert them to world space.
    b2Vec2 worldVertices[B2_MAX_POLYGON_VERTICES];
    for (int i = 0; i < vertexCount; i++)
    {
        worldVertices[i] = b2TransformPoint(transform, vertices[i]);
    }

    drawPolygonOutline(worldVertices, vertexCount, color, context);
}

/// Draw a circle.
void* vita2d_debug_draw::vita2dDrawCircleFcn( b2Vec2 center, float radius, b2HexColor color, void* context )
{

}

/// Draw a solid circle.
void* vita2d_debug_draw::vita2dDrawSolidCircleFcn( b2Transform transform, float radius, b2HexColor color, void* context )
{

}

/// Draw a solid capsule.
void* vita2d_debug_draw::vita2dDrawSolidCapsuleFcn( b2Vec2 p1, b2Vec2 p2, float radius, b2HexColor color, void* context )
{

}

/// Draw a line segment.
void* vita2d_debug_draw::vita2dDrawSegmentFcn( b2Vec2 p1, b2Vec2 p2, b2HexColor color, void* context )
{

}

/// Draw a transform. Choose your own length scale.
void* vita2d_debug_draw::vita2dDrawTransformFcn( b2Transform transform, void* context )
{

}

/// Draw a point.
void* vita2d_debug_draw::vita2dDrawPointFcn( b2Vec2 p, float size, b2HexColor color, void* context )
{

};

/// Draw a string in world space
void* vita2d_debug_draw::vita2dDrawStringFcn( b2Vec2 p, const char* s, b2HexColor color, void* context )
{

}