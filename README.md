TacoShell
=========

Framework and / or libraries (all kind of mashed together) and some C++ bindings, used by the game [Icebreakers](http://www.icebreakers-game.com/).

The provenance of the name was a silly little discussion at the office. :) Trail Mix and Ice Sculptor (after the ice "trails") were also tossed around.

This is a continuation of some of the code already developed in a [UI editor](https://github.com/ggcrunchy/ui-edit-v2) and some other projects, and
then honed over time to meet the demands of a game. It was targeted against the [Vision SDK](http://www.havok.com/products/vision-engine), though the
intent was to make it [adaptable](https://github.com/ggcrunchy/Old-Love2D-Demo).

Lua 5.1 and LuaJIT were out (at least once the project got going), but we already had A LOT of non-module stuff which would have been painful to port,
thus the "boot" files and associated loading scheme. Also, the GC often caught a case of the hiccoughs, so a lot of deep code ended up doing recycling,
plus we threw in an arena allocator for good measure.

Game-specific code is omitted, for the most part. A hint of some menus and the localization scheme remain, and most (all?) of the boot files themselves.
The vast majority of the C++ is elided too, since it's either game-specific as well or touches a lot of middleware.