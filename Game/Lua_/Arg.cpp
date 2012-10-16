#include "Lua_/Lua.h"
#include "Lua_/Arg.h"

// @brief Templated pop-and-return routine
template<typename T> T _popRetT (lua_State * L, T (*func)(lua_State *, int))
{
	T value = func(L, -1);

	lua_pop(L, 1);

	return value;
}

namespace Lua
{
	// @brief Validates and returns a signed char argument
	// @param L Lua state
	// @param index Argument index
	// @return signed char value
	sChar sC (lua_State * L, int index)
	{
		return sChar(luaL_checkint(L, index));
	}

	// @brief Validates and returns a signed short argument
	// @param L Lua state
	// @param index Argument index
	// @return signed short value
	sShort sS (lua_State * L, int index)
	{
		return sShort(luaL_checkint(L, index));
	}

	// @brief Validates and returns a signed long argument
	// @param L Lua state
	// @param index Argument index
	// @return signed long value
	sLong sL (lua_State * L, int index)
	{
		return sLong(luaL_checkint(L, index));
	}

	// @brief Validates and returns a signed int argument
	// @param L Lua state
	// @param index Argument index
	// @return signed int value
	sInt sI (lua_State * L, int index)
	{
		return sInt(luaL_checkint(L, index));
	}

	// @brief Validates, pops, and returns a signed char argument at the stack top
	// @param L Lua state
	// @return signed char value
	sChar sC_ (lua_State * L)
	{
		return _popRetT(L, sC);
	}

	// @brief Validates, pops, and returns a signed short argument at the stack top
	// @param L Lua state
	// @return signed short value
	sShort sS_ (lua_State * L)
	{
		return _popRetT(L, sS);
	}

	// @brief Validates, pops, and returns a signed long argument at the stack top
	// @param L Lua state
	// @return signed long value
	sLong sL_ (lua_State * L)
	{
		return _popRetT(L, sL);
	}

	// @brief Validates, pops, and returns a signed int argument at the stack top
	// @param L Lua state
	// @return signed int value
	sInt sI_ (lua_State * L)
	{
		return _popRetT(L, sI);
	}

	// @brief Validates and returns an unsigned char argument
	// @param L Lua state
	// @param index Argument index
	// @return unsigned char value
	uChar uC (lua_State * L, int index)
	{
		return uChar(luaL_checkint(L, index));
	}

	// @brief Validates and returns an unsigned short argument
	// @param L Lua state
	// @param index Argument index
	// @return unsigned short value
	uShort uS (lua_State * L, int index)
	{
		return uShort(luaL_checkint(L, index));
	}

	// @brief Validates and returns an unsigned long argument
	// @param L Lua state
	// @param index Argument index
	// @return unsigned long value
	uLong uL (lua_State * L, int index)
	{
		return uLong(luaL_checkint(L, index));
	}

	// @brief Validates and returns a signed int argument
	// @param L Lua state
	// @param index Argument index
	// @return unsigned int value
	uInt uI (lua_State * L, int index)
	{
		return uInt(luaL_checkint(L, index));
	}

	// @brief Validates, pops, and returns an unsigned char argument at the stack top
	// @param L Lua state
	// @return unsigned char value
	uChar uC_ (lua_State * L)
	{
		return _popRetT(L, uC);
	}

	// @brief Validates, pops, and returns an unsigned short argument at the stack top
	// @param L Lua state
	// @return unsigned short value
	uShort uS_ (lua_State * L)
	{
		return _popRetT(L, uS);
	}

	// @brief Validates, pops, and returns an unsigned long argument at the stack top
	// @param L Lua state
	// @return unsigned long value
	uLong uL_ (lua_State * L)
	{
		return _popRetT(L, uL);
	}

	// @brief Validates, pops, and returns an unsigned int argument at the stack top
	// @param L Lua state
	// @return unsigned int value
	uInt uI_ (lua_State * L)
	{
		return _popRetT(L, uI);
	}

	// @brief Validates and return a float argument
	// @param L Lua state
	// @param index Argument index
	// @return float value
	float F (lua_State * L, int index)
	{
		return float(luaL_checknumber(L, index));
	}

	// @brief Validates and return a double argument
	// @param L Lua state
	// @param index Argument index
	// @return double value
	double D (lua_State * L, int index)
	{
		return double(luaL_checknumber(L, index));
	}

	// @brief Validates, pops, and returns a float argument at the stack top
	// @param L Lua state
	// @return float value
	float F_ (lua_State * L)
	{
		return _popRetT(L, F);
	}

	// @brief Validates, pops, and returns a double argument at the stack top
	// @param L Lua state
	// @return double value
	double D_ (lua_State * L)
	{
		return _popRetT(L, D);
	}

	// @brief Validates and returns a bool argument
	// @param L Lua state
	// @param index Argument index
	// @return bool value
	bool B (lua_State * L, int index)
	{
		luaL_checktype(L, index, LUA_TBOOLEAN);

		return lua_toboolean(L, index) != 0;
	}

	// @brief Validates, pops, and returns a bool argument at the stack top
	// @param L Lua state
	// @return bool value
	bool B_ (lua_State * L)
	{
		return _popRetT(L, B);
	}

	// @brief Validates and returns a void * argument
	// @param L Lua state
	// @param index Argument index
	// @return void * value
	void * UD (lua_State * L, int index)
	{
		if (!lua_isuserdata(L, index)) luaL_error(L, "Argument %d is not a userdata", index);

		return lua_touserdata(L, index);
	}

	// @brief Validates and returns a char const * argument
	// @param L Lua state
	// @param index Argument index
	// @return char const * value
	char const * S (lua_State * L, int index)
	{
		return luaL_checkstring(L, index);
	}
}