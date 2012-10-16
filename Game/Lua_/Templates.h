#ifndef LUA_TEMPLATES_H
#define LUA_TEMPLATES_H

namespace Lua
{
	/*%%%%%%%%%%%%%%%% TEMPLATED HELPER FUNCTIONS %%%%%%%%%%%%%%%%*/

	// @brief Templated type stub
	template<typename T> char const * _typeT (void) { return ""; }

	// @brief Templated reference type stub
	template<typename T> char const * _rtypeT (void) { return ""; }

	// @brief Templated type accessor
	template<typename T> T * _pT (lua_State * L, int index)
	{
		// Given an instance, supply its memory; if it is a non-T type, report an error.
		// Otherwise, simply return the non-instance's memory.
		if (Class::IsInstance(L, index))
		{
			// If the instance is a T reference, look up its memory.
			if (Class::IsType(L, index, _rtypeT<T>())) return *(T **)UD(L, index);

			// Otherwise, point to its memory.
			if (!Class::IsType(L, index, _typeT<T>())) luaL_error(L, "Arg #%d: non-%s/%s", index, _typeT<T>(), _rtypeT<T>());
		}

		return (T *)UD(L, index);
	}

	// @brief Templated type accessor; 0 if unavailable
	template<typename T> T * _pTor0 (lua_State * L, int index)
	{
		if (!lua_isnoneornil(L, index)) return _pT<T>(L, index);

		return 0;
	}

	// @brief Templated member getter; builds a new object or fills in a passed one if available (passed-in object version)
	template<typename D> int _getmemberT_arg (lua_State * L, int index, D & (*ref)(lua_State *, int), char const * type, D const & d, bool bTop = true)
	{
		if (!lua_isnoneornil(L, index))
		{
			ref(L, index) = d;

			if (bTop) lua_settop(L, index);
		}

		else Lua_Class_New(L, type, "u", &d);

		return 1;
	}

	// @brief Templated member getter; builds a new object or fills in a passed one if available (reference version)
	template<typename O, typename D> int _getmemberT_ref (lua_State * L, O * pObject, int index, D & (*ref)(lua_State *, int), char const * type, void (O::*func)(D &) const, bool bTop = true)
	{
		D d;

		(pObject->*func)(d);

		return _getmemberT_arg(L, index, ref, type, d, bTop);
	}

	// @brief Templated member getter; builds a new object or fills in a passed one if available (returned object version)
	template<typename O, typename D> int _getmemberT_retv (lua_State * L, O * pObject, int index, D & (*ref)(lua_State *, int), char const * type, D (O::*func)(void) const, bool bTop = true)
	{
		return _getmemberT_arg(L, index, ref, type, (pObject->*func)(), bTop);
	}

	// @brief Templated boxed member get
	template<typename T> T * _boxedgetT (lua_State * L, int source)
	{
		return *(T **)UD(L, source);
	}

	// @brief Templated boxed member direct set
	template<typename T> int _boxedsetT (lua_State * L, int dest, T * value)
	{
		*(T **)UD(L, dest) = value;

		return 0;
	}

	// @brief Templated boxed member set
	template<typename T> int _boxedsetT (lua_State * L, int dest, int source)
	{
		return _boxedsetT(L, dest, _pT<T>(L, source));
	}

	// @brief Templated boxed member direct set (reference version)
	template<typename T> int _boxedsetT_ref (lua_State * L, int dest, T * value, bool bCheckTarget = true)
	{
		T ** target = (T **)UD(L, dest);

		if (value != 0) value->AddRef();
		if (bCheckTarget && *target != 0) (*target)->Release();

		*target = value;

		return 0;
	}

	// @brief Templated boxed member set (reference version)
	template<typename T> int _boxedsetT_ref (lua_State * L, int dest, int source, bool bCheckTarget = true)
	{
		return _boxedsetT_ref<T>(L, dest, _pTor0<T>(L, source), bCheckTarget);
	}

	// @brief Templated copy constructor
	template<typename T> int _copyT (lua_State * L, T & t)
	{
		Lua_Class_New(L, _typeT<T>(), "u", &t);	// t

		return 1;
	}

	// @brief Templated constructor setter (reference version)
	template<typename T> int _conssetT_ref (lua_State * L, int source)
	{
		return _boxedsetT_ref<T>(L, 1, source, false);
	}

	// @brief Templated constructor setter (reference version)
	template<typename T> int _conssetT_ref (lua_State * L, T * value)
	{
		return _boxedsetT_ref(L, 1, value, false);
	}

	// @brief Templated copy constructor
	template<typename T> int _consT_copy (lua_State * L)
	{
		return _boxedsetT<T>(L, 1, 2);
	}

	// @brief Templated constructor (reference version)
	template<typename T> int _consT_ref (lua_State * L)
	{
		return _conssetT_ref(L, new T);
	}

	// @brief Templated copy constructor (reference version)
	template<typename T> int _consT_ref_copy (lua_State * L)
	{
		return _conssetT_ref<T>(L, 2);
	}

	// @brief Templated copy constructor (reference / pointer version)
	template<typename T> int _consT_refp (lua_State * L)
	{
		return _conssetT_ref(L, _pT<T>(L, 2));
	}

	// @brief Templated copy constructor (reference / pointer or 0 version)
	template<typename T> int _consT_refpor0 (lua_State * L)
	{
		return _conssetT_ref(L, _pTor0<T>(L, 2));
	}

	// @brief Templated garbage collector (reference version)
	template<typename T> int _gcT_ref (lua_State * L)
	{
		return _boxedsetT_ref(L, 1, (T *)0);
	}

	// @brief Templated garbage collector (destructor version)
	template<typename T> int _gcT_dtor (lua_State * L)
	{
		((T *)UD(L, 1))->~T();

		return 0;
	}

	// @brief Installs a typed garbage-collected singleton
	template<typename T> T * _install_singletonT (lua_State * L)
	{
		T * singleton = (T *)lua_newuserdata(L, sizeof(T));	// ..., singleton

		new (singleton) T;

		lua_newtable(L);// ..., singleton, {}
		lua_pushcfunction(L, _gcT_dtor<T>);	// ..., singleton, {}, GC
		lua_setfield(L, -2, "__gc");// ..., singleton, { __gc = GC }
		lua_setmetatable(L, -2);// ..., singleton
		lua_pushboolean(L, true);	// ..., singleton, true
		lua_rawset(L, LUA_REGISTRYINDEX);	// ...

		return singleton;
	}
}

#endif // LUA_TEMPLATES_H