#ifndef LUA_SUPPORT_H
#define LUA_SUPPORT_H

#include <string>
#include <vector>
#include <cstdarg>
#include "Lua_/Lua.h"

namespace Lua
{
	int CallCore (lua_State * L, int count, int retc, char const * params, va_list & args, bool bProtected = false);
	int OverloadedNew (lua_State * L, char const * type, int argc);

	void StackView (lua_State * L);

	// @brief Overloaded function builder
	struct Overload {
		std::string mArgs;	// String used to fetch arguments
		lua_State * mL;	// Lua state

		Overload (lua_State * L, int argc);

		void AddDef (lua_CFunction func, ...);
	};
}

#endif // LUA_SUPPORT_H