#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Show 1Password SSH Request
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🔑
# @raycast.description Open the pending SSH key request from the 1Password menu bar item.

# Needs Raycast in System Settings → Privacy & Security → Accessibility.

# Opening 1Password's menu with an Accessibility "click" runs the menu inside
# that request, so 1Password stops answering until the menu closes. Post real
# mouse events instead, which leave it responsive, and put the cursor back.
on clickAt(px, py)
	do shell script "osascript -l JavaScript -e 'ObjC.import(\"CoreGraphics\"); const back = $.CGEventGetLocation($.CGEventCreate(null)); const p = {x: " & px & ", y: " & py & "}; [5, 1, 2].forEach(t => $.CGEventPost(0, $.CGEventCreateMouseEvent(null, t, p, 0))); $.CGWarpMouseCursorPosition(back)'"
end clickAt

on pressEsc()
	do shell script "osascript -l JavaScript -e 'ObjC.import(\"CoreGraphics\"); [true, false].forEach(d => $.CGEventPost(0, $.CGEventCreateKeyboardEvent(null, 53, d)))'"
end pressEsc

on centerOf(uiElement)
	tell application "System Events"
		set {ex, ey} to position of uiElement
		set {ew, eh} to size of uiElement
	end tell
	-- Whole numbers, so the text in the shell command never uses a locale's
	-- decimal comma.
	return {round (ex + ew / 2), round (ey + eh / 2)}
end centerOf

try
	tell application "System Events" to tell process "1Password"
		set statusItem to menu bar item 1 of menu bar 2
	end tell
	set {cx, cy} to centerOf(statusItem)
	clickAt(cx, cy)

	set menuReady to false
	tell application "System Events" to tell process "1Password"
		-- Poll for the menu instead of a fixed delay; gives up after ~1s.
		repeat 50 times
			try
				with timeout of 1 second
					if exists menu 1 of statusItem then
						set menuReady to true
						exit repeat
					end if
				end timeout
			end try
			delay 0.02
		end repeat
		if not menuReady then
			my pressEsc()
			return "Couldn't open the 1Password menu"
		end if
		-- Fetch all names in one Accessibility call; a whose-filter queries each item.
		with timeout of 2 seconds
			set itemNames to name of every menu item of menu 1 of statusItem
		end timeout
	end tell

	repeat with i from 1 to count of itemNames
		set itemName to item i of itemNames
		if itemName is not missing value and itemName contains "SSH" then
			tell application "System Events" to tell process "1Password"
				set sshItem to menu item i of menu 1 of statusItem
			end tell
			set {cx, cy} to centerOf(sshItem)
			clickAt(cx, cy)
			return
		end if
	end repeat

	pressEsc() -- no pending request, close the menu
	return "No pending SSH request"
on error errMsg number errNum
	pressEsc()
	return "Error " & errNum & ": " & errMsg
end try
