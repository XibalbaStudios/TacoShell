#ifndef ARENA_H
#define ARENA_H

void * SetLuaArena (lua_State * L, size_t base, size_t sizes[], int nsizes, char const * diagnostics);

template<size_t Count> void * SetLuaArena (lua_State * L, size_t base, size_t (&sizes)[Count], char const * diagnostics)
{
	return SetLuaArena(L, base, sizes, Count, diagnostics);
}

#endif // ARENA_H