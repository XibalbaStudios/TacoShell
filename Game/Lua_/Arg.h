#ifndef LUA_ARG_H
#define LUA_ARG_H

#include "AppTypes.h"
#include "Lua_/Lua.h"

namespace Lua
{
	/*%%%%%%%%%%%%%%%% ACCESS %%%%%%%%%%%%%%%%*/

	// Signed access
	sChar sC (lua_State * L, int index);
	sShort sS (lua_State * L, int index);
	sLong sL (lua_State * L, int index);
	sInt sI (lua_State * L, int index);

	sChar sC_ (lua_State * L);
	sShort sS_ (lua_State * L);
	sLong sL_ (lua_State * L);
	sInt sI_ (lua_State * L);

	// Unsigned access
	uChar uC (lua_State * L, int index);
	uShort uS (lua_State * L, int index);
	uLong uL (lua_State * L, int index);
	uInt uI (lua_State * L, int index);

	uChar uC_ (lua_State * L);
	uShort uS_ (lua_State * L);
	uLong uL_ (lua_State * L);
	uInt uI_ (lua_State * L);

	// Floating point access
	float F (lua_State * L, int index);
	double D (lua_State * L, int index);

	float F_ (lua_State * L);
	double D_ (lua_State * L);

	// Boolean access
	bool B (lua_State * L, int index);

	bool B_ (lua_State * L);

	// String access
	char const * S (lua_State * L, int index);

	// Memory access
	void * UD (lua_State * L, int index);
}

#endif // LUA_ARG_H