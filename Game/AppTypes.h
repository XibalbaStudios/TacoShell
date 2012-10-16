#ifndef APP_TYPES_H
#define APP_TYPES_H

// Typedefs
typedef signed int sInt;
typedef signed char sChar;
typedef signed short sShort;
typedef signed long sLong;
typedef unsigned int uInt;
typedef unsigned char uChar;
typedef unsigned short uShort;
typedef unsigned long uLong;

// Type helpers
template<typename T, int count> int ArrayN (T (&arr)[count])
{
	return count;
}

#endif // APP_TYPES_H