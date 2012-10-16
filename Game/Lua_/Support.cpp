#include "Lua_/Lua.h"
#include "Lua_/LibEx.h"
#include "Lua_/Helpers.h"
#include "Lua_/Support.h"

using namespace Lua;

// @brief Used to read arguments
struct Reader {
	// Members
	va_list & mArgs;// Variable argument list
	lua_State * mL;	// Lua state
	char const * mError;// Error to propagate
	char const * mParams;	// Parameter list
	int mHeight;// Table height
	int mTop;	// Original top of stack used to resolve negative indices
	bool mInKey;// If true, a key is being read
	bool mInValue;	// If true, a value is being read
	bool mShouldSkip;	// If true, do not add an element

	// Lifetime
	Reader (va_list & args, lua_State * L, char const * params, int top) : mArgs(args), mL(L), mError(0), mParams(params), mHeight(0), mTop(top), mInKey(false), mInValue(false), mShouldSkip(false) {}
	~Reader (void) { va_end(mArgs); }

	// @brief Pass an error down
	bool Error (char const * error)
	{
		if (0 == mError) mError = error;

		return false;
	}

	// @brief Loads a value from the stack 
	bool _a (void)
	{
		int arg = va_arg(mArgs, int);

		if (!(arg >= lua_upvalueindex(LUAI_MAXUPVALUES) && arg <= LUA_REGISTRYINDEX))
		{
			if (arg < 0) arg += 'a' == *mParams ? mTop : lua_gettop(mL) + 1;

			if (arg <= 0 || arg > lua_gettop(mL)) return Error("Bad index");
		}

		if (mInKey && lua_isnil(mL, arg)) return Error("Null key");

		if (!mShouldSkip) lua_pushvalue(mL, arg);	// ...[, arg]

		return true;
	}

	// @brief Loads a boolean
	void _b (void)
	{
		bool bArg = 'b' == *mParams ? va_arg(mArgs, bool) : 'T' == *mParams;

		if (!mShouldSkip) lua_pushboolean(mL, bArg);// ...[, bArg]
	}

	// @brief Loads a function
	void _f (void)
	{
		lua_CFunction func = va_arg(mArgs, lua_CFunction);

		if (!mShouldSkip) lua_pushcfunction(mL, func);	// ...[, func]
	}

	// @brief Loads an integer
	void _i (void)
	{
		int i = va_arg(mArgs, int);

		if (!mShouldSkip) lua_pushinteger(mL, i);	// ...[, i]
	}

	// @brief Loads a number
	void _n (void)
	{
		double n = va_arg(mArgs, double);

		if (!mShouldSkip) lua_pushnumber(mL, n);// ...[, n]
	}

	// @brief Loads a string
	void _s (void)
	{
		char const * str = va_arg(mArgs, char const *);

		if (!mShouldSkip) lua_pushstring(mL, str);	// ...[, str]
	}

	// @brief Loads a userdata
	bool _u (void)
	{
		void * ud = va_arg(mArgs, void *);

		if (!mShouldSkip)
		{
			if (ud == 0)
			{
				if (*mParams == 'U') return Error("Null userdata");

				lua_pushnil(mL);// ...[, nil]
			}

			else lua_pushlightuserdata(mL, ud);	// ...[, ud]
		}

		return true;
	}

	// @brief Loads a nil
	bool _0 (void)
	{
		if (mInKey) return Error("Null key");

		if (!mShouldSkip) lua_pushnil(mL);	// ...[, nil]

		return true;
	}

	// @brief Loads a global
	void _G (void)
	{
		char const * name = va_arg(mArgs, char const *);

		if (!mShouldSkip) GetGlobal(mL, name);	// ...[, global]
	}

	// @brief Loads a table
	bool _table (void)
	{
		++mHeight;

		if (!mShouldSkip) lua_newtable(mL);	// ...[, {}]

		for (++mParams; ; ++mParams)	// skip '{' at start, and skip over last parameter on each pass
		{
			int top = lua_gettop(mL);

			if (!ReadElement()) return Error("Unclosed table");	// ..., { ... }[, element]

			// If the stack has grown, append the element to the table.
			if (lua_gettop(mL) > top) Push(mL, -2);	// ..., { ..., [new top] = element }

			// On a '}' terminate a table (skipped over by caller).
			else if ('}' == *mParams) break;
		}

		--mHeight;

		return true;
	}

	// @brief Processes a conditional
	bool _C (void)
	{
		if (mInKey) return Error("Conditional key");
		if (mInValue) return Error("Conditional value");

		++mParams;	// Skip 'C' (value skipped by caller)

		bool bSkipSave = mShouldSkip, bDoSkip = !va_arg(mArgs, bool);

		if (!mShouldSkip) mShouldSkip = bDoSkip;
	
		if (!ReadElement()) return Error("Unfinished condition");	// ...[, value]

		mShouldSkip = bSkipSave;

		return true;
	}

	// @brief Processes a key
	bool _K (void)
	{
		++mParams;	// Skip 'K'

		mInKey = true;

		if (!ReadElement()) return Error("Missing key");	// ..., { ... }[, k]

		++mParams;	// Skip key (value skipped in table logic)

		mInKey = false;
		mInValue = true;

		if (!ReadElement()) return Error("Missing value");// ..., { ... }[, k, v]

		mInValue = false;

		if (!mShouldSkip) lua_settable(mL, -3);	// ..., { ...[, k = v] }

		return true;
	}

	// @brief Reads an element from the parameter set
	// @return If true, parameters remain
	bool ReadElement (void)
	{
		// Remove space characters.
		while (isspace(*mParams)) ++mParams;

		// Branch on argument type.
		switch (*mParams)
		{
		case '\0':	// End of list
			return false;
		case 'a':	// Add argument from the stack
		case 'r':
			return _a();
		case 'b':	// Add boolean
		case 'T':
		case 'F':
			_b();
			break;
		case 'f':	// Add function
			_f();
			break;
		case 'i':	// Add integer
			_i();
			break;
		case 'n':	// Add number
			_n();
			break;
		case 's':	// Add string
			_s();
			break;
		case 'u':	// Add userdata
		case 'U':
			return _u();
		case '0':	// Add nil
			return _0();
		case 'g':	// Add global
			_G();
			break;
		case '{':	// Begin table
			return _table();
		case '}':	// End table (error)
			if (0 == mHeight) return Error("Unopened table");
			break;
		case 'C':	// Evaluate condition
			return _C();
		case 'K':	// Key
			if (0 == mHeight) return Error("Key outside table");

			return _K();
		default:
			return Error("Bad type");
		}

		// Keep reading.
		return true;
	}
};

// @brief Core operation for various Lua operations called on the C++ end
// @param L Lua state
// @param count Count of arguments already added to stack
// @param retc Result count (may be MULT_RET)
// @param params Parameter descriptors
//		   a Argument (stack index, relative to initial stack top if negative; also accepts pseudo-indices)
//		   r Relative argument (same as 'a', but relative to current stack top if negative)
//		   b Boolean
//		   T true
//		   F false
//		   f Function
//		   i Integer
//		   n Number
//		   s String
//		   u Light userdata (if null, nil is used instead)
//		   U Light userdata, error on null
//		   0 Nil
//		   g Global (as per GetGlobal with no arguments)
//		   { Begin table (arguments added up to matching brace added)
//		   } End table
//		   C Condition boolean (if false, next parameter is skipped)
//		   K Next value is table key
// @param args Variable argument list
// @param bProtected If true, call is protected and throws any error
// @return Number of results of call
int Lua::CallCore (lua_State * L, int count, int retc, char const * params, va_list & args, bool bProtected)
{
	// Parse the arguments.
	int top = lua_gettop(L);

	Reader r(args, L, params, top - count);

	if (*params != '\0')
	{
		while (r.ReadElement()) ++r.mParams;

		count += lua_gettop(L) - top;

		if (!bProtected && r.mError != 0) luaL_error(L, r.mError);
	}

	// Invoke the function.
	int after = lua_gettop(L) - count - 1;

	if (bProtected)
	{
		// If a protected call raises an error, restore the stack to its precall state and
		// throw the error; if the error is not a string, indicate this.
		if (r.mError != 0 || PCall_EF(L, count, retc) != 0)
		{
			std::string error = r.mError != 0 ? r.mError : luaL_optstring(L, -1, "Caught non-string error");

			lua_settop(L, after);

			throw error;
		}
	}

	else lua_call(L, count, retc);

	return lua_gettop(L) - after;
}

// @brief Instantiates a class with an overloaded new function
// @param L Lua state
// @param type Type to instantiate
// @param argc Minimum argument count
// @return 1 (new instance on top of stack)
int Lua::OverloadedNew (lua_State * L, char const * type, int argc)
{
	if (lua_gettop(L) < argc) lua_settop(L, argc);

	Lua_Class_New(L, type, lua_gettop(L));

	return 1;
}

static int StringVectorPrintf (lua_State * L)
{
   std::vector<std::string> * vec = (std::vector<std::string> *)UD(L, lua_upvalueindex(1));

   GetGlobal(L, "string.format"); // format_str, ..., string.format

   lua_insert(L, 1); // string.format, format_str, ...

   lua_call(L, lua_gettop(L) - 1, 1); // result_str

   vec->push_back(S(L, 1));

   return 0;
}

void Lua::StackView (lua_State * L){

	lua_Debug ar;

	for (int i = 0; lua_getstack(L, i, &ar) != 0; i++) {
		// fill in lua_Debug
		lua_getinfo(L, "Sl", &ar);
		//get locals
		for (int j = 1 ; ; j++, lua_pop(L, 1)){
			const char* name = lua_getlocal(L, &ar, j);
			// break for if no name is returned, meaning no more locals
			if (name == NULL) break;
			// skip internal locals
			if(name[0] == '('){
				continue;
			}
			
			std::vector<std::string> vec;

			GetGlobal(L, "vardump.Print"); // local_var, vardump.Print

			lua_pushvalue(L, -2); // local_var, vardump.Print, local_var
			lua_pushlightuserdata(L, &vec); // local_var, vardump.Print, local_var, vec
			lua_pushcclosure(L, StringVectorPrintf, 1); // local_var, vardump.Print, local_var, StringVectorPrintf
			lua_call(L, 2, 0); // local_var
			// Place breakpoint here!!
		}
	}
}

// @brief Constructs an Overload
// @param L Lua state
// @param argc Count of arguments to overloaded function
Overload::Overload (lua_State * L, int argc) : mL(L), mArgs(argc, 's')
{
	Lua_Class_New(L, "Multimethod", "i", argc);// ..., M
}

// @brief Adds a function defintion
// @param func Function to be invoked
// @note Vararg parameters are the argument types on which to invoke
// @note Overload must be on the stack top
void Overload::AddDef (lua_CFunction func, ...)
{
	va_list args;	va_start(args, func);

	lua_getfield(mL, -1, "Define");	// ..., G, G.Define
	lua_pushvalue(mL, -2);	// ..., G, G.Define, G
	lua_pushcfunction(mL, func);// ..., G, G.Define, G, func

	CallCore(mL, 2, 0, mArgs.c_str(), args);
}