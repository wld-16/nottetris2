//
// Created by wld on 28.09.26.
//

#include <vector>
#include <box2d/box2d.h>

#include "include/nottetris.h"

int lua_initWorld(lua_State *L)
{
    int argc = lua_gettop(L);
#ifndef SKIP_ERROR_HANDLING
    if (argc != 3)
        return luaL_error(L, "wrong number of arguments");
#endif

    unsigned int xg = luaL_checkinteger(L, 1);
    unsigned int yg = luaL_checkinteger(L, 2);
    bool sleep = luaL_checkinteger(L, 3) == 1;

    b2Vec2 b2_vec2{ .x = static_cast<float>(xg), .y = static_cast<float>(yg)};
    auto* worldDef = new b2WorldDef();
    worldDef->gravity = b2_vec2;
    auto b2_create_world = b2CreateWorld(worldDef);
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
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    auto m = static_cast<float>(luaL_checknumber(L, 4));
    auto i = static_cast<float>(luaL_checknumber(L, 5));

    auto* body_def = new b2BodyDef{
        .position = {.x = static_cast<float>(x), .y = static_cast<float>(y)},
        .angularVelocity = i,
        .gravityScale = m
    };

    auto b2_body_id = b2CreateBody(b2_load_world_id, body_def);
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

    std::vector<int> int_vector;
    for (size_t i = 1; i <= len; i++) {
        // Pushes table[i] onto the top of the stack
        lua_rawgeti(L, 2, i);

        // Ensure the value at table[i] is actually an integer/number
        if (!lua_isnumber(L, -1)) {
            int_vector.clear();
            return luaL_error(L, "Element at index %d is not a number.", (int)i);
        }
        int_vector.push_back((int)lua_tointeger(L, -1));

        lua_pop(L, 1);
    }

    std::vector<b2Vec2> vertices;
    vertices.reserve(vertex_count);

    for (size_t i = 0; i < vertex_count; i++) {
        b2Vec2 point;
        point.x = static_cast<float>(int_vector[i * 2]);
        point.y = static_cast<float>(int_vector[i * 2 + 1]);
        vertices.push_back(point);
    }

    b2Hull b2_hull = b2ComputeHull(vertices.data(), vertex_count);

    if (b2_hull.count == 0) {
        return luaL_error(L, "Failed to compute a valid convex hull from the provided points.");
    }

    b2Polygon polygonDef = b2MakePolygon(&b2_hull, 0.0);
    b2ShapeDef shape_def = b2DefaultShapeDef();

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
    int x = luaL_checkinteger(L, 2);
    int y = luaL_checkinteger(L, 3);
    b2Vec2 position = {static_cast<float>(x), static_cast<float>(y)};

    int width = luaL_checkinteger(L, 4);
    int height = luaL_checkinteger(L, 5);

    float angle = static_cast<float>(luaL_checknumber(L, 6));
    b2Rot rotation = {.s = angle};

    b2Polygon b2_offset_box = b2MakeOffsetBox(width, height, position, rotation);

    b2ShapeDef shape_def = b2DefaultShapeDef();

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
    return 1;
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
    uint64_t b2_body_id = static_cast<uint64_t>(luaL_checknumber(L, 1));
    auto b2_load_body_id = b2LoadBodyId(b2_body_id);

    auto b2_body_get_position = b2Body_GetPosition(b2_load_body_id);

    lua_pushnumber(L, b2_body_get_position.x);
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
    uint64_t b2_body_id = static_cast<uint64_t>(luaL_checknumber(L, 1));
    auto b2_load_body_id = b2LoadBodyId(b2_body_id);

    auto b2_body_get_position = b2Body_GetPosition(b2_load_body_id);

    lua_pushnumber(L, b2_body_get_position.y);
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
    u_int64_t b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);
    b2Vec2 b2_linear_velocity = b2Vec2 {
        .x = static_cast<float>(luaL_checknumber(L, 2)),
        .y = static_cast<float>(luaL_checknumber(L, 3))
    };

    b2Body_SetLinearVelocity(body_id, b2_linear_velocity);
    return 1;
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
    u_int64_t b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);
    float linear_damping = static_cast<float>(luaL_checknumber(L, 2));

    b2Body_SetLinearDamping(body_id, linear_damping);
    return 1;
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
    u_int64_t b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);

    b2Body_ApplyMassFromShapes(body_id);
    return 1;
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
    u_int64_t b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);
    bool bullet = static_cast<bool>(luaL_checknumber(L, 2));

    b2Body_SetBullet(body_id, bullet);
    return 1;
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
    u_int64_t b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);

    auto b2_body_get_world_center_of_mass = b2Body_GetWorldCenterOfMass(body_id);
    lua_pushnumber(L, b2_body_get_world_center_of_mass.x);
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
    u_int64_t b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);

    auto b2_body_get_world_center_of_mass = b2Body_GetWorldCenterOfMass(body_id);
    lua_pushnumber(L, b2_body_get_world_center_of_mass.y);
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
    u_int64_t b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);

    float fx = static_cast<float>(luaL_checknumber(L, 2));
    float fy = static_cast<float>(luaL_checknumber(L, 3));
    float x = static_cast<float>(luaL_checknumber(L, 4));
    float y = static_cast<float>(luaL_checknumber(L, 5));
    b2Body_ApplyForce(body_id, b2Vec2{fx, fy}, b2Vec2{x, y}, true);
    return 1;
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
    u_int64_t b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);

    auto b2_body_get_linear_velocity = b2Body_GetLinearVelocity(body_id);
    lua_pushnumber(L, b2_body_get_linear_velocity.x);
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
    u_int64_t b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);

    auto b2_body_get_linear_velocity = b2Body_GetLinearVelocity(body_id);
    lua_pushnumber(L, b2_body_get_linear_velocity.y);
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
    u_int64_t b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
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
    u_int64_t b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);
    float angular_velocity = static_cast<float>(luaL_checknumber(L, 2));

    b2Body_SetAngularVelocity(body_id, angular_velocity);
    return 1;
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
    u_int64_t b2_body_id = static_cast<u_int64_t>(luaL_checknumber(L, 1));
    b2BodyId body_id = b2LoadBodyId(b2_body_id);
    float torque = static_cast<float>(luaL_checknumber(L, 2));

    b2Body_ApplyTorque(body_id, torque, true);
    return 1;
}

//Register our Phsysics functions
const luaL_Reg Physics_functions[] = {
    {"newWorld",            lua_initWorld },
    {"newBody",             lua_initBody },
    {"newPolygonShape",     lua_initPolygonShape },
    {"newRectangleShape",   lua_initRectableShape },
    {"update",              lua_update },
    {"getX",               lua_getX },
    {"getY",               lua_getY },
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
    {"applyTorque",         lua_applyTorque},
    {0, 0}
};

void luaPhysics_init(lua_State *L) {
    lua_newtable(L);
    luaL_setfuncs(L, Physics_functions, 0);
    lua_setglobal(L, "Physics");
    lua_newtable(L);
}