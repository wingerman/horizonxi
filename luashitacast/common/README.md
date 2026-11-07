# luashitacast/common/

Shared Lua loaded by profiles with `gFunc.LoadFile('common\\<file>.lua')`. LuAshitacast searches the
character folder first, then this folder, so a character can override a common file by shadowing it.

Empty for now. Candidates: a small shared helper exposing town/aketon zone lists, elemental staff
tables, and the BST/SMN pet-action lists, so job files stop each carrying their own copy. Anything
third-party placed here gets a provenance line in this README (source, commit, license).
