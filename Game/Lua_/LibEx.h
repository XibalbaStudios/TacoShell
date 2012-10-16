#ifndef LUA_LIB_EX_H
#define LUA_LIB_EX_H

#include <string>
#include "Lua_/Lua.h"
#include "Lua_/Arg.h"

namespace Bindings
{
	int open_std (lua_State * L);
}

namespace Lua
{
	namespace Class
	{
		// @brief Class definition
		struct Def {
			std::string mBases;	// Base types
			uInt mArr;	// Environment: Array count
			uInt mRec;	// Environment: Record count
			uInt mSize;	// Class size
			bool mShared;	// If true, use shared environment table

			Def (uInt size = 0, char const * bases = 0, bool bShared = false) : mArr(0), mRec(0), mSize(size), mShared(bShared)
			{
				if (bases != 0) mBases = bases;
			}
		};

		void Define (lua_State * L, char const * name, luaL_reg const * methods, lua_CFunction newf, Def const & def = Def());
		void Define (lua_State * L, char const * name, luaL_reg const * methods, Def const & def = Def());
		void Define (lua_State * L, char const * name, luaL_reg const * methods, char const * closures[], lua_CFunction newf, Def const & def = Def());
		void Define (lua_State * L, char const * name, luaL_reg const * methods, char const * closures[], Def const & def = Def());
		void New (lua_State * L, char const * name, int count);
		void New (lua_State * L, char const * name, char const * params, ...);

		void GetFuncInfo (char *& file, char *& func, int & line);
		void SetFuncInfo (char * file, char * func, int line);

		bool IsInstance (lua_State * L, int index);
		bool IsType (lua_State * L, int index, char const * type);
	}

	int FM_Loader (lua_State * L);

	int LoadDir (lua_State * L, char const * boot);
	int LoadFile (lua_State * L, char const * name);
}

#define Lua_Class_New Lua::Class::SetFuncInfo(__FILE__, __FUNCTION__, __LINE__), Lua::Class::New

#endif // LUA_LIB_EX_H