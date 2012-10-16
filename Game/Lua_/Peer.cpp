#include "Lua_/Lua.h"
#include "Lua_/Arg.h"
#include "Lua_/Peer.h"
#include <cassert>

using namespace Lua;

// @brief Data indices
enum {
	_not_datai,
	eDescriptors,	// Descriptor table index
	eBoxed	// Boxed boolean index
};

// @brief Descriptor indices
enum {
	_not_desci,
	eDOffset,	// Offset index
	eDName,	// Name index
	eDType	// Type index
};

// @brief Gets member fields
// @return Pointer to field memory
static uChar * GetFields (lua_State * L)
{
	lua_rawgeti(L, -1, eDOffset);	// data, key[, value], D, D[key], offset
	lua_rawgeti(L, -2, eDType);	// data, key[, value], D, D[key], offset, type

	return static_cast<uChar *>(UD(L, 1)) + uI(L, -2);
}

#define F_(t, p) lua_pushnumber(L, *(t *)p)
#define I_(t, p) lua_pushinteger(L, *(t *)p)

// @brief Indexes a member
// @note data: Object memory
static void IndexMember (lua_State * L)
{
	// Point to the requested member.
	uChar * pData = GetFields(L);	// data, key, D, D[key], offset, type

	// Return the appropriate type.
	switch (uI(L, 6))
	{
	case Member_Reg::ePointer:
		lua_pushlightuserdata(L, *(void **)pData);	// data, key, D, D[key], offset, type, pointer
		break;
	case Member_Reg::eSChar:
		I_(sChar, pData);	// data, key, D, D[key], offset, type, schar
		break;
	case Member_Reg::eSShort:
		I_(sShort, pData);	// data, key, D, D[key], offset, type, sshort
		break;
	case Member_Reg::eSLong:
		I_(sLong, pData);	// data, key, D, D[key], offset, type, slong
		break;
	case Member_Reg::eSInt:
		I_(sInt, pData);	// data, key, D, D[key], offset, type, sint
		break;
	case Member_Reg::eUChar:
		I_(uChar, pData);	// data, key, D, D[key], offset, type, uchar
		break;
	case Member_Reg::eUShort:
		I_(uShort, pData);	// data, key, D, D[key], offset, type, ushort
		break;
	case Member_Reg::eULong:
		I_(uLong, pData);	// data, key, D, D[key], offset, type, ulong
		break;
	case Member_Reg::eUInt:
		I_(uInt, pData);// data, key, D, D[key], offset, type, uint
		break;
	case Member_Reg::eFloat:	
		F_(float, pData);	// data, key, D, D[key], offset, type, fsingle
		break;
	case Member_Reg::eDouble:
		F_(double, pData);	// data, key, D, D[key], offset, type, fdouble
		break;
	case Member_Reg::eString:
		lua_pushstring(L, *(char **)pData);	// data, key, D, D[key], offset, type, string
		break;
	case Member_Reg::eBoolean:
		lua_pushboolean(L, *(bool *)pData);	// data, key, D, D[key], offset, type, boolean
		break;
	default:
		luaL_error(L, "Member __index: Bad type");
	}
}

#undef F_
#undef I_

template<typename T> static void Set (lua_State * L, uChar * pData, T (*func)(lua_State *, int))
{
	*(T *)pData = func(L, 3);
}

// @brief Assigns to a member
// @note data: Object memory
static void NewIndexMember (lua_State * L)
{
	// Point to the requested member.
	uChar * pData = GetFields(L);	// data, key, value, D, D[key], offset, type

	// Assign the appropriate type.
	switch (uI(L, 7))
	{
	case Member_Reg::ePointer:
		Set(L, pData, UD);
		break;
	case Member_Reg::eSChar:
		Set(L, pData, sC);
		break;
	case Member_Reg::eSShort:
		Set(L, pData, sS);
		break;
	case Member_Reg::eSLong:
		Set(L, pData, sL);
		break;
	case Member_Reg::eSInt:
		Set(L, pData, sI);
		break;
	case Member_Reg::eUChar:
		Set(L, pData, uC);
		break;
	case Member_Reg::eUShort:
		Set(L, pData, uS);
		break;
	case Member_Reg::eULong:
		Set(L, pData, uL);
		break;
	case Member_Reg::eUInt:
		Set(L, pData, uI);
		break;
	case Member_Reg::eFloat:
		Set(L, pData, F);
		break;
	case Member_Reg::eDouble:
		Set(L, pData, D);
		break;
	case Member_Reg::eString:
		*(char const **)pData = S(L, 3);
		break;
	case Member_Reg::eBoolean:
		Set(L, pData, B);
		break;
	default:
		luaL_error(L, "Member __newindex: Bad type");
	}
}

// @brief Looks up member data
// @note _U1: Boxed boolean
static void Lookup (lua_State * L)
{
	lua_rawgeti(L, lua_upvalueindex(1), eBoxed);// object, key[, value], bBoxed

	bool bBoxed = lua_toboolean(L, -1) != 0;

	lua_pop(L, 1);	// object, key[, value]

	if (bBoxed) lua_pushlightuserdata(L, *(void **)UD(L, 1));	// object, key[, value], data

	else lua_pushvalue(L, 1);// object, key[, value], object
}

// @brief __index closure
// @note _U1: Member descriptor and boxed boolean
// @note _U2: Member getter table
// @note object: Object being accessed
// @note key: Lookup key
static int Index (lua_State * L)
{
	Lookup(L);	// object, key, data

	// If a getter exists for this member, return the result of its invocation.
	lua_pushvalue(L, 2);// object, key, data, key
	lua_gettable(L, lua_upvalueindex(2));	// object, key, data, getter

	if (!lua_isnil(L, 4))
	{
		lua_insert(L, 1);	// getter, object, key, data
		lua_call(L, 3, 1);	// result
	}

	// Otherwise, look up the member. If it exists, index it; otherwise, return nil
	// to let the __index metamethod continue.
	else
	{
		lua_pop(L, 1);	// object, key, data
		lua_replace(L, 1);	// data, key

		// Look up the member. If it exists, index it; otherwise, return nil to let
		// the __index metamethod continue.
		lua_rawgeti(L, lua_upvalueindex(1), eDescriptors);	// data, key, D
		lua_pushvalue(L, 2);// data, key, D, key
		lua_gettable(L, 3);	// data, key, D, D[key]

		if (!lua_isnil(L, 4)) IndexMember(L);	// result
	}

	return 1;
}

// @brief __newindex closure
// @note _U1: Member descriptor and boxed boolean
// @note _U2: Member setter table
// @note object: Object being accessed
// @note key: Lookup key
// @note value: Value to assign
static int NewIndex (lua_State * L)
{
	Lookup(L);	// object, key, value, data

	// If a setter exists for this member, invoke it. If it returns a result, propagate
	// the __newindex call if allowed.
	lua_pushvalue(L, 2);// object, key, value, data, key
	lua_gettable(L, lua_upvalueindex(2));	// object, key, value, data, setter

	if (!lua_isnil(L, 5))
	{
		lua_insert(L, 1);	// setter, object, key, value, data
		lua_call(L, 4, 0);
	}

	// Otherwise, look up the member. If it exists, assign to it; otherwise, return a
	// result to let the __newindex metamethod continue.
	else
	{
		lua_pop(L, 1);	// object, key, value, data
		lua_replace(L, 1);	// data, key, value
		lua_rawgeti(L, lua_upvalueindex(1), eDescriptors);	// data, key, value, D
		lua_pushvalue(L, 2);// data, key, value, D, key
		lua_gettable(L, 4);	// data, key, value, D, D[key]

		if (!lua_isnil(L, 5)) NewIndexMember(L);
	}

	return 0;
}

// @brief Pushes __index and __newindex member binding closures onto stack
// @param L Lua state
// @param getters [optional] Member getter functions
// @param setters [optional] Member setter functions
// @param members [optional] Member descriptors
// @param count Count of member descriptors
// @param bBoxed If true, datum is boxed
// @note At least one of getters, setters, or members must be non-0 (if members, count must also be non-0)
void Lua::BindPeer (lua_State * L, luaL_reg const * getters, luaL_reg const * setters, Member_Reg const * members, int count, bool bBoxed)
{
	assert(0 == count || members != 0);
	assert(getters != 0 || setters != 0 || (members != 0 && count > 0));

	lua_createtable(L, 4, 0);	// data

	// Build up member data.
	lua_createtable(L, 0, count);	// data, M

	for (int i = 0; i < count; ++i)
	{
		lua_pushstring(L, members[i].mName.c_str());// data, M, name
		lua_createtable(L, 2, 0);	// data, M, name, {}
		lua_pushinteger(L, members[i].mOffset);	// data, M, name, D, offset
		lua_pushinteger(L, members[i].mType);	// data, M, name, D, offset, type
		lua_rawseti(L, -3, eDType);	// data, M, name, D = { type = type }, offset
		lua_rawseti(L, -2, eDOffset);	// data, M, name, D = { type, offset = offset }
		lua_settable(L, -3);// data, M = { ..., name = D }
	}

	lua_rawseti(L, -2, eDescriptors);	// data = { descriptors = M }

	// Install lookup information.
	lua_pushboolean(L, bBoxed);	// data, bBoxed
	lua_rawseti(L, -2, eBoxed);	// data = { descriptors, bBoxed }

	// Build __index closure.
	lua_pushvalue(L, -1);	// data, data
	lua_newtable(L);// data, data, {}

	if (getters != 0) luaL_register(L, 0, getters);

	lua_pushcclosure(L, Index, 2);	// data, __index

	// Build __newindex closure.
	lua_insert(L, -2);	// __index, data
	lua_newtable(L);// __index, data, {}

	if (setters != 0) luaL_register(L, 0, setters);

	lua_pushcclosure(L, NewIndex, 2);	// __index, __newindex
}