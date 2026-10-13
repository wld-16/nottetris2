//
// Created by wld on 28.09.26.
//

#include <vector>
#include <cstring>
#include <unordered_map>
#include <box2d/box2d.h>

#include "vita2d_debug_draw.h"
#include "include/nottetris.h"

// Maps a world ID to the Lua registry reference of the collision callback
// function set via Physics.setCallbacks.
static std::unordered_map<uint32_t, int> g_collisionCallbackRefs;

// LÖVE scales all spatial quantities by 1/meter before handing them to
// Box2D, and scales them back up by meter on the way out. The game works in
// pixel units (shapes are 32px wide, gravity is 500px/s^2, etc.), but Box2D
// expects meters. Without this scaling the shapes are 30x too large, the mass
// is ~900x too large (area scales with meter^2), and forces/torques become
// negligible — which is why applyForce(70) had no visible effect.
static const float PHYSICS_METER = 30.0f;

static inline float scaleDown(float v) { return v / PHYSICS_METER; }
static inline float scaleUp(float v) { return v * PHYSICS_METER; }

int lua_initWorld(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 3)
        return luaL_error(L, "wrong number of arguments");
#endif

    float xg = static_cast<float>(luaL_checknumber(L, 1));
    float yg = static_cast<float>(luaL_checknumber(L, 2));
    bool sleep = luaL_checkinteger(L, 3) == 1;

    b2Vec2 b2_vec2{ .x = scaleDown(xg), .y = scaleDown(yg) };
    b2WorldDef worldDef = b2DefaultWorldDef();
    worldDef.gravity = b2_vec2;
    auto b2_create_world = b2CreateWorld(&worldDef);
    b2World_EnableSleeping(b2_create_world, sleep);
    uint32_t b2_store_world_id = b2StoreWorldId(b2_create_world);
    lua_pushinteger(L, b2_store_world_id);
    return 1;
}

int lua_initBody(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 5)
        return luaL_error(L, "wrong number of arguments");
#endif

    uint64_t world = luaL_checkinteger(L, 1);
    auto b2_load_world_id = b2LoadWorldId(world);
    float x = static_cast<float>(luaL_checknumber(L, 2));
    float y = static_cast<float>(luaL_checknumber(L, 3));

    // The 4th argument selects the body type. LÖVE 0.7 passes a mass number
    // (0 = static, >0 = dynamic); LÖVE 0.8+ passes the string "static" or
    // "dynamic". Without an explicit type Box2D defaults to b2_staticBody,
    // which ignores gravity and forces — the blocks never move.
    b2BodyType body_type = b2_dynamicBody;
    if (lua_isnumber(L, 4)) {
        body_type = lua_tonumber(L, 4) > 0.0f ? b2_dynamicBody : b2_staticBody;
    } else if (lua_isstring(L, 4)) {
        const char* type_str = lua_tostring(L, 4);
        if (strcmp(type_str, "static") == 0) {
            body_type = b2_staticBody;
        } else if (strcmp(type_str, "dynamic") == 0) {
            body_type = b2_dynamicBody;
        } else if (strcmp(type_str, "kinematic") == 0) {
            body_type = b2_kinematicBody;
        } else {
            return luaL_error(L, "unknown body type: %s", type_str);
        }
    } else {
        return luaL_error(L, "body type must be a number or string");
    }

    // The 5th argument is the initial angle in the LÖVE 0.7 API.
    float angle = 0.0f;
    if (argc >= 5 && lua_isnumber(L, 5)) {
        angle = static_cast<float>(lua_tonumber(L, 5));
    }

    b2BodyDef body_def = b2DefaultBodyDef();
    body_def.type = body_type;
    body_def.position = {scaleDown(x), scaleDown(y)};
    body_def.rotation = b2MakeRot(angle);

    auto b2_body_id = b2CreateBody(b2_load_world_id, &body_def);
    uint64_t b2_store_body_id = b2StoreBodyId(b2_body_id);
    lua_pushnumber(L, (lua_Number)b2_store_body_id);
    return 1;
}

int lua_initPolygonShape(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if(argc != 2)
        return luaL_error(L, "wrong number of arguments");
#endif
    uint64_t bodyId = (uint64_t) luaL_checknumber(L, 1);
    auto b2_load_body_id = b2LoadBodyId(bodyId);

    luaL_checktype(L, 2 , LUA_TTABLE);
    size_t len = lua_objlen(L, 2);

    if (len == 0) {
        return luaL_error(L, "The provided list is empty.");
    }

    if (len % 2 != 0) {
        return luaL_error(L, "The provided list must contain an even number of elements.");
    }

    int vertex_count = len / 2;
    if (vertex_count < 3) {
        return luaL_error(L, "A polygon needs at least 3 vertices.");
    }
    if (vertex_count > B2_MAX_POLYGON_VERTICES) {
        return luaL_error(L, "A polygon may have at most %d vertices.", B2_MAX_POLYGON_VERTICES);
    }

    std::vector<float> coord_vector;
    for (size_t i = 1; i <= len; i++) {
        // Pushes table[i] onto the top of the stack
        lua_rawgeti(L, 2, i);

        // Ensure the value at table[i] is actually an integer/number
        if (!lua_isnumber(L, -1)) {
            coord_vector.clear();
            return luaL_error(L, "Element at index %d is not a number.", (int)i);
        }
        coord_vector.push_back((float)lua_tonumber(L, -1));

        lua_pop(L, 1);
    }

    std::vector<b2Vec2> vertices;
    vertices.reserve(vertex_count);

    for (size_t i = 0; i < vertex_count; i++) {
        b2Vec2 point;
        point.x = scaleDown(coord_vector[i * 2]);
        point.y = scaleDown(coord_vector[i * 2 + 1]);
        vertices.push_back(point);
    }

    b2Hull b2_hull = b2ComputeHull(vertices.data(), vertex_count);

    if (b2_hull.count == 0) {
        return luaL_error(L, "Failed to compute a valid convex hull from the provided points.");
    }

    b2Polygon polygonDef = b2MakePolygon(&b2_hull, 0.0);
    b2ShapeDef shape_def = b2DefaultShapeDef();
    shape_def.enableContactEvents = true;

    auto b2_polygon_shape = b2CreatePolygonShape(b2_load_body_id, &shape_def, &polygonDef);
    uint64_t b2_store_shape_id = b2StoreShapeId(b2_polygon_shape);
    lua_pushnumber(L, (lua_Number)b2_store_shape_id);
    return 1;
}

int lua_initRectableShape(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if(argc != 6)
        return luaL_error(L, "wrong number of arguments");
#endif
    uint64_t bodyId = (uint64_t) luaL_checknumber(L, 1);
    auto b2_load_body_id = b2LoadBodyId(bodyId);
    float x = static_cast<float>(luaL_checknumber(L, 2));
    float y = static_cast<float>(luaL_checknumber(L, 3));
    b2Vec2 position = {scaleDown(x), scaleDown(y)};

    float width = static_cast<float>(luaL_checknumber(L, 4));
    float height = static_cast<float>(luaL_checknumber(L, 5));

    float angle = static_cast<float>(luaL_checknumber(L, 6));
    b2Rot rotation = b2MakeRot(angle);

    // LÖVE passes full width/height; b2MakeOffsetBox takes half-extents.
    b2Polygon b2_offset_box = b2MakeOffsetBox(scaleDown(width) / 2.0f, scaleDown(height) / 2.0f, position, rotation);

    b2ShapeDef shape_def = b2DefaultShapeDef();
    shape_def.enableContactEvents = true;

    auto b2_polygon_shape = b2CreatePolygonShape(b2_load_body_id, &shape_def, &b2_offset_box);
    uint64_t b2_store_shape_id = b2StoreShapeId(b2_polygon_shape);
    lua_pushnumber(L, (lua_Number)b2_store_shape_id);
    return 1;
}

int lua_update(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 2)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    uint32_t b2_world_id = luaL_checkinteger(L, 1);
    auto b2_load_world_id = b2LoadWorldId(b2_world_id);
    float dt = static_cast<float>(luaL_checknumber(L, 2));

    b2World_Step(b2_load_world_id, dt, 4);

    // Process contact begin events: call the Lua collision callback
    // registered via Physics.setCallbacks for this world.
    auto ref_it = g_collisionCallbackRefs.find(b2_world_id);
    if (ref_it != g_collisionCallbackRefs.end()) {
        b2ContactEvents events = b2World_GetContactEvents(b2_load_world_id);
        for (int i = 0; i < events.beginCount; i++) {
            b2ShapeId shape_a = events.beginEvents[i].shapeIdA;
            b2ShapeId shape_b = events.beginEvents[i].shapeIdB;

            // Retrieve Lua user data references stored via b2Shape_SetUserData.
            void* ud_a = b2Shape_GetUserData(shape_a);
            void* ud_b = b2Shape_GetUserData(shape_b);

            // Push the stored callback onto the stack.
            lua_rawgeti(L, LUA_REGISTRYINDEX, ref_it->second);

            // Push shape data arguments (or nil if no data was set).
            if (ud_a != nullptr) {
                lua_rawgeti(L, LUA_REGISTRYINDEX, (int)(intptr_t)ud_a);
            } else {
                lua_pushnil(L);
            }
            if (ud_b != nullptr) {
                lua_rawgeti(L, LUA_REGISTRYINDEX, (int)(intptr_t)ud_b);
            } else {
                lua_pushnil(L);
            }

            lua_pcall(L, 2, 0, 0);
        }
    }
    return 0;
}

int lua_drawWorld(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 2)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_world_id = luaL_checkinteger(L, 1);
    auto b2_load_world_id = b2LoadWorldId(b2_world_id);
    float scale = static_cast<float>(luaL_checknumber(L, 2));

    // Box2D coordinates are in meters (scaled down by PHYSICS_METER), while
    // the Lua-side physicsscale converts the game's internal pixel space to
    // screen pixels. Multiply both to go from meters to screen pixels.
    float draw_scale = scale * PHYSICS_METER;

    b2DebugDraw debugDraw = b2DefaultDebugDraw();
    debugDraw.DrawPolygonFcn = vita2d_debug_draw::vita2dDrawPolygonFcn;
    debugDraw.DrawSolidPolygonFcn = vita2d_debug_draw::vita2dDrawSolidPolygonFcn;
    debugDraw.drawShapes = true;
    debugDraw.context = &draw_scale;


    b2World_Draw(b2_load_world_id, &debugDraw);
    return 0;
}

int lua_getX(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 1)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<uint64_t>(luaL_checknumber(L, 1));
    auto b2_load_body_id = b2LoadBodyId(b2_body_id);

    auto b2_body_get_position = b2Body_GetPosition(b2_load_body_id);

    lua_pushnumber(L, scaleUp(b2_body_get_position.x));
    return 1;
}

int lua_getY(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 1)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<uint64_t>(luaL_checknumber(L, 1));
    auto b2_load_body_id = b2LoadBodyId(b2_body_id);

    auto b2_body_get_position = b2Body_GetPosition(b2_load_body_id);

    lua_pushnumber(L, scaleUp(b2_body_get_position.y));
    return 1;
}

int lua_getAngle(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 1)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<uint64_t>(luaL_checknumber(L, 1));
    auto b2_load_body_id = b2LoadBodyId(b2_body_id);

    b2Rot rotation = b2Body_GetRotation(b2_load_body_id);
    lua_pushnumber(L, atan2f(rotation.s, rotation.c));
    return 1;
}

int lua_getMass(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 1)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<uint64_t>(luaL_checknumber(L, 1));
    auto b2_load_body_id = b2LoadBodyId(b2_body_id);

    lua_pushnumber(L, b2Body_GetMass(b2_load_body_id));
    return 1;
}

int lua_setLinearVelocity(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 3)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);
    b2Vec2 b2_linear_velocity = b2Vec2 {
        .x = scaleDown(static_cast<float>(luaL_checknumber(L, 2))),
        .y = scaleDown(static_cast<float>(luaL_checknumber(L, 3)))
    };

    b2Body_SetLinearVelocity(body_id, b2_linear_velocity);
    return 0;
}

int lua_setLinearDamping(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 2)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);
    auto linear_damping = static_cast<float>(luaL_checknumber(L, 2));

    b2Body_SetLinearDamping(body_id, linear_damping);
    return 0;
}

int lua_setMassFromShapes(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 1)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);

    // In LÖVE 0.7, bodies are created with mass 0 (static). Calling
    // setMassFromShapes() computes mass from attached shapes and transitions
    // the body to dynamic. Box2D v3 separates these concerns, so we set the
    // type explicitly here.
    b2Body_SetType(body_id, b2_dynamicBody);
    b2Body_ApplyMassFromShapes(body_id);
    return 0;
}

int lua_setBullet(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 2)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);
    bool bullet = static_cast<bool>(luaL_checknumber(L, 2));

    b2Body_SetBullet(body_id, bullet);
    return 0;
}

int lua_getWorldCenterX(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 1)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);

    auto b2_body_get_world_center_of_mass = b2Body_GetWorldCenterOfMass(body_id);
    lua_pushnumber(L, scaleUp(b2_body_get_world_center_of_mass.x));
    return 1;
}

int lua_getWorldCenterY(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 1)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);

    auto b2_body_get_world_center_of_mass = b2Body_GetWorldCenterOfMass(body_id);
    lua_pushnumber(L, scaleUp(b2_body_get_world_center_of_mass.y));
    return 1;
}

int lua_applyForce(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 5)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);

    auto fx = static_cast<float>(luaL_checknumber(L, 2));
    auto fy = static_cast<float>(luaL_checknumber(L, 3));
    auto x = static_cast<float>(luaL_checknumber(L, 4));
    auto y = static_cast<float>(luaL_checknumber(L, 5));

    b2Body_ApplyForce(body_id, b2Vec2{.x = fx, .y = fy}, b2Vec2{.x = scaleDown(x), .y = scaleDown(y)}, true);
    return 0;
}

int lua_getLinearVelocityX(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 1)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);

    auto b2_body_get_linear_velocity = b2Body_GetLinearVelocity(body_id);
    lua_pushnumber(L, scaleUp(b2_body_get_linear_velocity.x));
    return 1;
}

int lua_getLinearVelocityY(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 1)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);

    auto b2_body_get_linear_velocity = b2Body_GetLinearVelocity(body_id);
    lua_pushnumber(L, scaleUp(b2_body_get_linear_velocity.y));
    return 1;
}

int lua_getAngularVelocity(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 1)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);

    auto b2_body_get_linear_velocity = b2Body_GetAngularVelocity(body_id);
    lua_pushnumber(L, b2_body_get_linear_velocity);
    return 1;
}

int lua_setAngularVelocity(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 2)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);
    auto angular_velocity = static_cast<float>(luaL_checknumber(L, 2));

    b2Body_SetAngularVelocity(body_id, angular_velocity);
    return 0;
}

int lua_applyTorque(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 2)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);
    auto torque = static_cast<float>(luaL_checknumber(L, 2));

    b2Body_ApplyTorque(body_id, torque, true);
    return 0;
}

int lua_setCallbacks(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 2)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif

    u_int32_t b2_world_id = static_cast<u_int32_t>(luaL_checkinteger(L, 1));
    b2WorldId world_id = b2LoadWorldId(b2_world_id);

    // The 2nd argument is the Lua collision callback function.
    // Store a reference to it in the Lua registry so we can call it
    // later from lua_update when contact events are processed.
    luaL_checktype(L, 2, LUA_TFUNCTION);

    // If a previous callback was registered for this world, release it.
    auto ref_it = g_collisionCallbackRefs.find(b2_world_id);
    if (ref_it != g_collisionCallbackRefs.end()) {
        luaL_unref(L, LUA_REGISTRYINDEX, ref_it->second);
    }

    // Store a new reference to the callback function.
    int ref = luaL_ref(L, LUA_REGISTRYINDEX);
    g_collisionCallbackRefs[b2_world_id] = ref;

    return 0;
}

int lua_setShapeData(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 2)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    uint64_t b2_shape_id = static_cast<uint64_t>(luaL_checknumber(L, 1));
    b2ShapeId shape_id = b2LoadShapeId(b2_shape_id);

    // Store a reference to the Lua data value (2nd argument) in the
    // Lua registry, and save the ref integer as the shape's user data
    // pointer so it can be retrieved during collision callbacks.
    int ref = luaL_ref(L, LUA_REGISTRYINDEX);
    b2Shape_SetUserData(shape_id, (void*)(intptr_t)ref);
    return 0;
}

int lua_getPoints(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 1)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif

    auto shape_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    auto b2_load_shape_id = b2LoadShapeId(shape_id);
    auto b2_shape_get_polygon = b2Shape_GetPolygon(b2_load_shape_id);

    // b2Shape_GetPolygon returns vertices in the body's local frame. The game
    // expects world coordinates (it compares Y against line positions in world
    // space and passes them to getLocalPoint). Convert each vertex to world.
    b2BodyId b2_body_id = b2Shape_GetBody(b2_load_shape_id);

    size_t size = b2_shape_get_polygon.count * 2;
    lua_createtable(L, size, 0);

    // 2. Loop through your C array
    for (int i = 0; i < size; i++) {
        int vi = i / 2;
        b2Vec2 world = b2Body_GetWorldPoint(b2_body_id, b2_shape_get_polygon.vertices[vi]);
        if (i % 2 == 0)
        {
            lua_pushnumber(L, scaleUp(world.x));
        } else
        {
            lua_pushnumber(L, scaleUp(world.y));
        }

        // Pops the number from the top and assigns it to table[i + 1]
        // (Lua arrays conventionally start at 1)
        lua_rawseti(L, -2, i + 1);
    }
    return 1;
}

int lua_setFriction(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 2)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto shape_id = static_cast<uint64_t>(luaL_checknumber(L, 1));
    b2ShapeId b2_shape_Id = b2LoadShapeId(shape_id);
    auto friction = static_cast<float>(luaL_checknumber(L, 2));

    b2Shape_SetFriction(b2_shape_Id, friction);

    return 0;
}

int lua_testSegment(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 5)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto shape_id = static_cast<uint64_t>(luaL_checknumber(L, 1));
    b2ShapeId b2_shape_id = b2LoadShapeId(shape_id);

    float x1 = static_cast<float>(luaL_checknumber(L, 2));
    float y1 = static_cast<float>(luaL_checknumber(L, 3));
    float x2 = static_cast<float>(luaL_checknumber(L, 4));
    float y2 = static_cast<float>(luaL_checknumber(L, 5));

    b2RayCastInput input;
    input.origin = {scaleDown(x1), scaleDown(y1)};
    input.translation = {scaleDown(x2 - x1), scaleDown(y2 - y1)};
    input.maxFraction = 1.0f;

    b2CastOutput output = b2Shape_RayCast(b2_shape_id, &input);

    if (output.hit)
    {
        lua_pushnumber(L, static_cast<lua_Number>(output.fraction));
        return 1;
    }

    lua_pushnil(L);
    return 1;
}

int lua_getLocalPoint(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 3)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<uint64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);

    float wx = static_cast<float>(luaL_checknumber(L, 2));
    float wy = static_cast<float>(luaL_checknumber(L, 3));

    b2Vec2 local = b2Body_GetLocalPoint(body_id, b2Vec2{scaleDown(wx), scaleDown(wy)});
    lua_pushnumber(L, scaleUp(local.x));
    lua_pushnumber(L, scaleUp(local.y));
    return 2;
}

int lua_getWorldPoint(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 3)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<uint64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);

    float lx = static_cast<float>(luaL_checknumber(L, 2));
    float ly = static_cast<float>(luaL_checknumber(L, 3));

    b2Vec2 world = b2Body_GetWorldPoint(body_id, b2Vec2{scaleDown(lx), scaleDown(ly)});
    lua_pushnumber(L, scaleUp(world.x));
    lua_pushnumber(L, scaleUp(world.y));
    return 2;
}

int lua_destroyBody(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 1)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<uint64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);

    b2DestroyBody(body_id);
    return 0;
}

int lua_setAngle(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 2)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto b2_body_id = static_cast<uint64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);
    float angle = static_cast<float>(luaL_checknumber(L, 2));

    b2Vec2 pos = b2Body_GetPosition(body_id);
    b2Body_SetTransform(body_id, pos, b2MakeRot(angle));
    return 0;
}

int lua_destroyShape(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 1)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto shape_id = static_cast<uint64_t>(luaL_checknumber(L, 1));
    b2ShapeId b2_shape_id = b2LoadShapeId(shape_id);

    b2DestroyShape(b2_shape_id, true);
    return 0;
}

int lua_testPoint(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 3)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto shape_id = static_cast<uint64_t>(luaL_checknumber(L, 1));
    b2ShapeId b2_shape_id = b2LoadShapeId(shape_id);

    float x = static_cast<float>(luaL_checknumber(L, 2));
    float y = static_cast<float>(luaL_checknumber(L, 3));

    bool hit = b2Shape_TestPoint(b2_shape_id, b2Vec2{scaleDown(x), scaleDown(y)});
    lua_pushboolean(L, hit ? 1 : 0);
    return 1;
}

int lua_setDensity(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 2)
    {
        return luaL_error(L, "wrong number of arguments");
    }
#endif
    auto shape_id = static_cast<uint64_t>(luaL_checknumber(L, 1));
    b2ShapeId b2_shape_id = b2LoadShapeId(shape_id);
    float density = static_cast<float>(luaL_checknumber(L, 2));

    b2Shape_SetDensity(b2_shape_id, density, true);
    return 0;
}

//Register our Phsysics functions
const luaL_Reg Physics_functions[] = {
    {"newWorld",            lua_initWorld },
    {"newBody",             lua_initBody },
    {"newPolygonShape",     lua_initPolygonShape },
    {"newRectangleShape",   lua_initRectableShape },
    {"update",              lua_update },
    {"drawWorld",           lua_drawWorld },
    {"getX",               lua_getX },
    {"getY",               lua_getY },
    {"getAngle",           lua_getAngle },
    {"getMass",            lua_getMass },
    {"setLinearVelocity",   lua_setLinearVelocity },
    {"setLinearDamping",    lua_setLinearDamping },
    {"setMassFromShapes", lua_setMassFromShapes },
    {"setBullet",           lua_setBullet},
    {"getWorldCenterX",      lua_getWorldCenterX},
    {"getWorldCenterY",      lua_getWorldCenterY},
    {"applyForce",          lua_applyForce},
    {"getLinearVelocityX",   lua_getLinearVelocityX},
    {"getLinearVelocityY",   lua_getLinearVelocityY},
    {"getAngularVelocity",   lua_getAngularVelocity},
    {"setAngularVelocity",   lua_setAngularVelocity},
    {"setCallbacks",          lua_setCallbacks},
    {"setShapeData",          lua_setShapeData},
    {"applyTorque",         lua_applyTorque},
    {"getPoints",         lua_getPoints},
    {"setFriction",         lua_setFriction},
    {"testSegment",        lua_testSegment},
    {"getLocalPoint",      lua_getLocalPoint},
    {"getWorldPoint",      lua_getWorldPoint},
    {"destroyBody",        lua_destroyBody},
    {"setAngle",            lua_setAngle},
    {"destroyShape",        lua_destroyShape},
    {"testPoint",           lua_testPoint},
    {"setDensity",          lua_setDensity},
    {0, 0}
};

void luaPhysics_init(lua_State *L) {
    lua_newtable(L);
    luaL_setfuncs(L, Physics_functions, 0);
    lua_setglobal(L, "Physics");
    lua_newtable(L);
}