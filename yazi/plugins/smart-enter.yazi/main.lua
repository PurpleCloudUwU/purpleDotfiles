--- @sync entry
-- Enter on a folder goes into it (like "l"), on a file it opens it as usual.
-- Without this, Enter "opens" folders with $EDITOR.
return {
	entry = function()
		local h = cx.active.current.hovered
		ya.emit(h and h.cha.is_dir and "enter" or "open", { hovered = true })
	end,
}
