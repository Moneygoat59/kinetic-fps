class_name TerminalEntry
extends Resource
## One item on a terminal's drive (TerminalDrive): a TerminalFolder or a TerminalFile. Drives are .tres files under
## res://content/terminals/ (tools/README.md "Terminals"); the game only reads them.

@export var name := ""               ## as listed on the screen, e.g. "REPORT_04.TXT" (upper case reads best in VT323)
@export var meta := ""               ## right-hand column: a date, a size, a code; empty = a folder shows its item count
