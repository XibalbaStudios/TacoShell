#ifndef LUA_HELPERS_H
#define LUA_HELPERS_H

#include "Lua_/Lua.h"

namespace Lua
{
	/*%%%%%%%%%%%%%%%% INITIALIZATION %%%%%%%%%%%%%%%%*/

	void LoadLibs (lua_State * L, lua_CFunction libs[]);

	/*%%%%%%%%%%%%%%%% HELPERS %%%%%%%%%%%%%%%%*/

	int Boot (lua_State * L, char const * path, char const * name, int arg = 0, char const * ext = 0, int loader = 0);
	int Call (lua_State * L, char const * name, int retc, char const * params, ...);
	int CallMethod (lua_State * L, char const * source, char const * name, int retc, char const * params, ...);
	int CallMethod (lua_State * L, int source, char const * name, int retc, char const * params, ...);
	int PCall (lua_State * L, char const * name, int retc, char const * params, ...);
	int PCallMethod (lua_State * L, char const * source, char const * name, int retc, char const * params, ...);
	int PCallMethod (lua_State * L, int source, char const * name, int retc, char const * params, ...);

	void CacheAndGet (lua_State * L, char const * name, void * key);
	void CacheAndGet (lua_State * L, lua_CFunction func);
	void GetGlobal (lua_State * L, char const * name);
	void Pop (lua_State * L, int index, bool bPutOnStack = false);
	void Push (lua_State * L, int index);
	void Register (lua_State * L, char const * name, luaL_reg const * funcs, int env = 0);
	void SetGlobal (lua_State * L, char const * name);
	void Top (lua_State * L, int index);
	void Unpack (lua_State * L, int source, int start = 1, int end = -1);

	int GetN (lua_State * L, int index);
	int PCall_EF (lua_State * L, int argc, int retc);

	bool IsCallable (lua_State * L, int index);

	/*%%%%%%%%%%%%%%%% INLINE HELPER FUNCTIONS %%%%%%%%%%%%%%%%*/

	// @brief Absolutizes acceptable indices
	inline void IndexAbsolute (lua_State * L, int & index)
	{
		int top = lua_gettop(L);

		if (index < 0 && index >= -top) index += top + 1;
	}
}

#endif // LUA_HELPERS_H