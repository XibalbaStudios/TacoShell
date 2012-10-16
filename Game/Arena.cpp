#include "Lua_/Lua.h"
#include "Arena.h"
#include <stdlib.h>
#include <string.h>

// @brief Free list links
struct Link {
	Link * mNext;	// Next free link
};

// @brief Store for a given size
struct Bank {
	int mCount;	// Number of allocations
	Link * mFree;	// Free list head
	ptrdiff_t mEnd;	// Displacement of end from start
};

// @brief Memory state
struct Memory {
	// Members
	lua_Alloc mFunc;// Original function
	void * mData;	// Original data
	size_t mBase;	// Minimum power-of-2 size
	size_t mMax;// Maximum size
	int mCount;	// Number of slots
	Bank mBanks[1];	// Size banks

	// Indicates whether the pointer is in the arena
	bool InDataRegion (void * ptr) const
	{
		char * region = GetDataRegion();

		return ptr >= region && ptr < region + mBanks[mCount - 1].mEnd;
	}

	// Find the slot of the best-fit bank for this size
	int Slot (size_t size) const
	{
		if (size > mMax) return mCount;

		int slot = 0;

		for (size_t max = mBase; size > max; ++slot, max *= 2);

		return slot;
	}

	// Find the slot of the bank from which this pointer was drawn
	int Slot (void * ptr) const
	{
		int slot = 0;

		for (char * region = GetDataRegion(); ptr > region + mBanks[slot].mEnd; ++slot);

		return slot;
	}

	// Attempts to allocate from this bank
	void * Allocate (int slot)
	{
		Link * link = mBanks[slot].mFree;

		if (link != 0)
		{
			mBanks[slot].mFree = link->mNext;

			++mBanks[slot].mCount;
		}

		return link;
	}

	// Attempts to find any free block in a range of banks
	void * Find (int start, int end)
	{
		for (int i = start; i < end; ++i)
		{
			void * ptr = Allocate(i);

			if (ptr != 0) return ptr;
		}

		return 0;
	}

	// Releases memory into the arena
	void FreeToArena (void * ptr)
	{
		Link * link = (Link *)ptr;

		int slot = Slot(ptr);

		link->mNext = mBanks[slot].mFree;

		mBanks[slot].mFree = link;

		--mBanks[slot].mCount;
	}

	// Moves data to new memory, releasing the old memory
	void * Realloc (void * alloc, void * ptr, size_t size)
	{
		memcpy(alloc, ptr, size);

		FreeToArena(ptr);

		return alloc;
	}

	// Points to the data region of the arena
	char * GetDataRegion (void) const { return (char *)&mBanks[mCount]; }
};

// @brief Allocator
static void * Alloc (void * ud, void * ptr, size_t osize, size_t nsize)
{
	Memory * memory = (Memory *)ud;

	// If this is a new block, try to allocate from the arena. If this fails (size is too
	// large or all candidate banks are full), pass the request on to the original allocator.
	// Return the result of whichever option is chosen.
	int nslot = memory->Slot(nsize);

	if (osize == 0 && nsize != 0)
	{
		void * alloc = memory->Find(nslot, memory->mCount);

		return alloc != 0 ? alloc : memory->mFunc(memory->mData, 0, 0, nsize);
	}

	// From this point on, all operations involve old memory. If this memory is outside the
	// arena (including null pointers, if both sizes were 0), pass it on to the original
	// allocator and return the result.
	if (!memory->InDataRegion(ptr)) return memory->mFunc(memory->mData, ptr, osize, nsize);

	// If the new size is 0, free the memory and quit.
	if (nsize == 0)
	{
		memory->FreeToArena(ptr);

		return 0;
	}

	// From this point on, the original memory is known to belong to the arena, and thus will
	// always have a valid slot. If the new size maps to this same slot, there is no point in
	// reallocating it, so the original pointer is returned.
	int oslot = memory->Slot(ptr);

	if (nslot == oslot) return ptr;

	// At this point, if the memory is being grown, any allocations must occur from those banks
	// able to satisfy at least the new size. If all such banks are full, the request is passed
	// to the original allocator. If either of these yields a valid pointer, the contents of
	// the old memory are transferred over and it is returned; otherwise it returns null.
	if (osize < nsize)
	{
		void * alloc = memory->Find(nslot, memory->mCount);

		if (alloc == 0) alloc = memory->mFunc(memory->mData, 0, 0, nsize);

		return alloc != 0 ? memory->Realloc(alloc, ptr, osize) : 0;
	}

	// The final case is that the memory is being shrunk. All of the smaller banks satisfying
	// the new size are checked, favoring smaller banks. If a block is available, the contents
	// of the old memory are transferred over, and it is returned. Otherwise, the original
	// pointer is returned.
	void * alloc = memory->Find(nslot, oslot);

	return alloc != 0 ? memory->Realloc(alloc, ptr, nsize) : ptr;
}

// @brief Gets basic memory diagnostics
static int Diagnostics (lua_State * L)
{
	Memory * memory = (Memory *)lua_touserdata(L, lua_upvalueindex(1));

	ptrdiff_t cur = 0;

	for (int i = 0, size = memory->mBase; i < memory->mCount; ++i, size *= 2)
	{
		ptrdiff_t diff = memory->mBanks[i].mEnd - cur;

		lua_pushinteger(L, memory->mBanks[i].mCount);	// t, count
		lua_rawseti(L, 1, i * 2 + 1);	// t = { ..., count }
		lua_pushinteger(L, diff / size);// t, size
		lua_rawseti(L, 1, i * 2 + 2);	// t = { ..., count, size }

		cur += diff;
	}

	lua_pushinteger(L, memory->mCount);	// t, count
	lua_pushinteger(L, memory->mBase);	// t, count, base
	
	return 2;
}

// @brief Sets the Lua arena memory manager
void * SetLuaArena (lua_State * L, size_t base, size_t sizes[], int nsizes, char const * diagnostics)
{
	if (nsizes == 0 || sizeof(Link) > base) return 0;

	// Given a set of tuned sizes, find the total size of the data region.
	size_t total = 0, coeff = base;

	for (int i = 0; i < nsizes; ++i, coeff *= 2)
	{
		if (sizes[i] == 0) return 0;

		total += coeff * sizes[i];
	}

	// Allocate a large block for the arena and construct it. Keep the original allocator.
	Memory * memory = (Memory *)malloc(sizeof(Memory) + sizeof(Bank) * (nsizes - 1) + total + sizeof(double));

	if (0 == memory) return 0;

	memory->mBase = base;
	memory->mMax = coeff / 2;
	memory->mCount = nsizes;
	memory->mFunc = lua_getallocf(L, &memory->mData);

	// Set up the banks, formatting all the memory as free lists.
	char * start = memory->GetDataRegion(), * offset = start, * prev, * next;

	for (int i = 0, coeff = base; i < nsizes; ++i, coeff *= 2)
	{
		memory->mBanks[i].mCount = 0;
		memory->mBanks[i].mFree = (Link *)offset;

		for (size_t j = 0; j < sizes[i]; ++j, prev = offset, offset = next)
		{
			next = offset + coeff;

			((Link *)offset)->mNext = (Link *)next;
		}

		((Link *)prev)->mNext = 0;

		memory->mBanks[i].mEnd = offset - start;
	}

	// Register the arena allocator, plus some utilities.
	lua_setallocf(L, Alloc, memory);

	if (diagnostics != 0)
	{
		lua_pushlightuserdata(L, memory);	// memory
		lua_pushcclosure(L, Diagnostics, 1);// Diagnostics
		lua_setglobal(L, diagnostics);	//
	}

	return memory;
}