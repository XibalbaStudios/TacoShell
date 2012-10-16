#include "Lua_/Lua.h"
#include "Lua_/LibEx.h"
#include "Lua_/Helpers.h"
#include "Lua_/Support.h"
#include "Lua_/Types.h"
#include <SCRIPT_MANAGER>
#include <cassert>

namespace Lua
{
	// @brief Configures a new Lua state
	// @param L Lua state
	// @param libs Libraries to load
	void LoadLibs (lua_State * L, lua_CFunction libs[])
	{
		for (int i = 0; libs[i] != 0; ++i)
		{
			lua_pushcfunction(L, libs[i]);	// ..., lib

			if (PCall_EF(L, 0, 0) != 0) throw std::string(S(L, -1));
		}
	}

	// @brief Defines a class
	// @param L Lua state
	// @param name Type name
	// @param methods Methods to associate with class
	// @param cons Constructor
	// @param def Class definition
	void Class::Define (lua_State * L, char const * name, luaL_reg const * methods, lua_CFunction cons, Def const & def)
	{
		Class::Define(L, name, methods, 0, cons, def);
	}

	// @brief Defines a class, with new function on the stack top
	// @param L Lua state
	// @param name Type name
	// @param methods Methods to associate with class
	// @param def Class definition
	void Class::Define (lua_State * L, char const * name, luaL_reg const * methods, Def const & def)
	{
		char const * dummy[] = { 0 };

		Class::Define(L, name, methods, dummy, def);
	}

	// @brief Defines a class, with closures on the stack
	// @param L Lua state
	// @param name Type name
	// @param methods Methods to associate with class
	// @param closures Closure names
	// @param cons Constructor
	// @param def Class definition
	void Class::Define (lua_State * L, char const * name, luaL_reg const * methods, char const * closures[], lua_CFunction cons, Def const & def)
	{
		lua_pushcfunction(L, cons);	// ..., cons

		Class::Define(L, name, methods, closures, def);
	}

	// @brief Shared environment instance allocator
	// @note meta: Metatable
	// @note _U1: Instance size
	// @note _U2: Environment
	static int SharedAlloc (lua_State * L)
	{
		lua_newuserdata(L, uI(L, lua_upvalueindex(1)));	// meta, ud
		lua_insert(L, 1);	// ud, meta
		lua_setmetatable(L, 1);	// ud
		lua_pushvalue(L, lua_upvalueindex(2));	// ud, env
		lua_setfenv(L, 1);	// ud

		return 1;
	}

	// @brief Unique environment instance allocator
	// @note meta: Metatable
	// @note _U1: Instance size
	// @note _U2: Array size
	// @note _U3: Hash size
	static int UniqueAlloc (lua_State * L)
	{
		lua_newuserdata(L, uI(L, lua_upvalueindex(1)));	// meta, ud
		lua_insert(L, 1);	// ud, meta
		lua_setmetatable(L, 1);	// ud
		lua_createtable(L, sI(L, lua_upvalueindex(2)), sI(L, lua_upvalueindex(3)));	// ud, env
		lua_setfenv(L, 1);	// ud

		return 1;
	}

	// @brief Default __index metamethod
	// @note _E: Object environment
	static int Index (lua_State * L)
	{
		lua_getfenv(L, 1);	// object, key, env
		lua_replace(L, 1);	// env, key
		lua_rawget(L, 1);	// env, value

		return 1;
	}

	// @brief Default __newindex metamethod
	// @note _E: Object environment
	static int NewIndex (lua_State * L)
	{
		lua_getfenv(L, 1);	// object, key, value, env
		lua_replace(L, 1);	// env, key, value
		lua_rawset(L, 1);	// env

		return 0;
	}

	// @brief Defines a class, with closures on the stack and new function at the top
	// @param L Lua state
	// @param name Type name
	// @param methods Methods to associate with class
	// @param closures Closure names
	// @param def Class definition
	void Class::Define (lua_State * L, char const * name, luaL_reg const * methods, char const * closures[], Def const & def)
	{
		assert(name != 0);
		assert(methods != 0 || closures != 0);

		// Count the closures.
		int count = 0;

		while (closures != 0 && closures[count] != 0) ++count;

		// Install the constructor.
		lua_insert(L, -count - 1);	// cons, ...

		// Load methods, starting with default __index / __newindex metamethods.
		lua_newtable(L);// cons, ..., M
		lua_pushcfunction(L, Index);// cons, ..., M, Index
		lua_setfield(L, -2, "__index");	// cons, ..., M = { __index = Index }
		lua_pushcfunction(L, NewIndex);	// cons, ..., M, NewIndex
		lua_setfield(L, -2, "__newindex");	// cons, ..., M = { __index, __newindex = NewIndex }

		if (methods != 0) luaL_register(L, 0, methods);

		// Load closures.
		for (int i = 0; i < count; ++i)
		{
			lua_pushstring(L, closures[i]);	// cons, ..., M, name
			lua_pushvalue(L, -count - 2 + i);	// cons, ..., M, name, closure
			lua_settable(L, -3);// cons, ..., M = { ..., name = closure }
		}

		lua_insert(L, -count - 2);	// M, cons, ...
		lua_pop(L, count);	// M, cons

		// Build an allocator.
		lua_pushinteger(L, def.mSize);	// M, cons, size

		if (def.mShared)
		{
			lua_createtable(L, def.mArr, def.mRec);	// M, cons, size, shared
			lua_pushcclosure(L, SharedAlloc, 2);// M, cons, SharedAlloc
		}

		else
		{
			lua_pushinteger(L, def.mArr);	// M, cons, size, narr
			lua_pushinteger(L, def.mRec);	// M, cons, size, narr, nrec
			lua_pushcclosure(L, UniqueAlloc, 3);// M, cons, UniqueAlloc
		}

		// Assign any parameters.
		if (!def.mBases.empty()) Call(L, "class.Define", 0, "saa{ Kss Ksa }", name, -3, -2, "base", def.mBases.c_str(), "alloc", -1);

		else Call(L, "class.Define", 0, "saa{ Ksa }", name, -3, -2, "alloc", -1);

		lua_pop(L, 3);
	}

	// @brief Dummy variable; class.New is cached under its address
	static int _New;

	// @brief Instantiates a class
	// @param L Lua state
	// @param name Type name
	// @param count Count of parameters on stack
	void Class::New (lua_State * L, char const * name, int count)
	{
		CacheAndGet(L, "class.New", &_New);	// class.New

		lua_pushstring(L, name);// ..., class.New, name
		lua_insert(L, -2 - count);	// name, ..., class.New 
		lua_insert(L, -2 - count);	// class.New, name, ...
		lua_call(L, count + 1, 1);	// I

		SetFuncInfo(0, 0, 0);
	}

	// @brief Instantiates a class
	// @param L Lua state
	// @param name Type name
	// @param params Parameter descriptors (q.v. CallCore)
	// @note Vararg parameters are the arguments
	void Class::New (lua_State * L, char const * name, char const * params, ...)
	{
		CacheAndGet(L, "class.New", &_New);	// class.New

		lua_pushstring(L, name);// class.New, name

		va_list args;	va_start(args, params);

		CallCore(L, 1, 1, params, args);

		SetFuncInfo(0, 0, 0);
	}

	// @brief Dummy variable; class.IsInstance is cached under its address
	static int _IsInstance;

	// @brief Indicates whether an item is an instance
	// @param L Lua state
	// @param index Index of argument
	// @return If true, item is an instance
	bool Class::IsInstance (lua_State * L, int index)
	{
		IndexAbsolute(L, index);

		CacheAndGet(L, "class.IsInstance", &_IsInstance);// class.IsInstance

		lua_pushvalue(L, index);// class.IsInstance, arg
		lua_call(L, 1, 1);	// bIsInstance

		bool bIsInstance = lua_toboolean(L, -1) != 0;

		lua_pop(L, 1);

		return bIsInstance;
	}

	// @brief Dummy variable; class.IsType is cached under its address
	static int _IsType;

	// @brief Indicates whether an item is of the given type
	// @param L Lua state
	// @param index Index of item
	// @param type Type name
	// @param return If true, item is of the type
	bool Class::IsType (lua_State * L, int index, char const * type)
	{
		IndexAbsolute(L, index);

		CacheAndGet(L, "class.IsType", &_IsType);// class.IsType

		lua_pushvalue(L, index);// class.IsType, arg
		lua_pushstring(L, type);// class.IsType, arg, type
		lua_call(L, 2, 1);	// bIsType

		bool bIsType = lua_toboolean(L, -1) != 0;

		lua_pop(L, 1);

		return bIsType;
	}

	// @brief Function info
	static char * s_file;
	static char * s_func;
	static int s_line;

	// @brief Gets the C++ function info
	void Class::GetFuncInfo (char *& file, char *& func, int & line)
	{
		file = s_file;
		func = s_func;
		line = s_line;
	}

	// @brief Sets the C++ function info
	void Class::SetFuncInfo (char * file, char * func, int line)
	{
		s_file = file;
		s_func = func;
		s_line = line;
	}

	// @brief
	int Lua::FM_Loader (lua_State * L)
	{
		const char * pszFilename = S(L, 1);

		FILE_STREAM * pIn = CREATE_FILESTREAM(pszFilename, 0);

		if (0 == pIn)
		{
			lua_pushnil(L);	// file, nil
			lua_pushfstring(L, "Could not open file: %s", pszFilename);	// file, nil, error

			return 2;
		}

		int iScriptLen = pIn->GetSize();

		TEMP_BUFFER<16 * 1024> buffer(iScriptLen + 1);

		char *szBuffer = (char *)buffer.GetBuffer();

		pIn->Read(szBuffer, iScriptLen);

		szBuffer[iScriptLen] = 0;

		pIn->Close();

		// Load the string as a chunk.
		if (luaL_loadbuffer(L, szBuffer, iScriptLen, pszFilename) != 0)	// file[, chunk]
		{
			lua_pushnil(L);	// file, nil
			lua_insert(L, -2);	// file, nil, error

			return 2;
		}

		return 1;
	}

	// @brief
	int Lua::LoadDir (lua_State * L, char const * boot)
	{
		CacheAndGet(L, Lua::FM_Loader);	// ..., loader

		int loader = -1;

		IndexAbsolute(L, loader);

		int result = Lua::Boot(L, "", boot, 0, 0, loader);

		lua_remove(L, loader);	// ...

		return result;
	}

	// @brief
	int Lua::LoadFile (lua_State * L, char const * name)
	{
		CacheAndGet(L, Lua::FM_Loader);	// ..., loader

		lua_pushstring(L, name);// ..., loader, name

		return PCall_EF(L, 1, 1);	// file
	}
}