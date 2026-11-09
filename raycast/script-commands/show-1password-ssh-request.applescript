#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Show 1Password SSH Request
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🔑
# @raycast.description Open the pending SSH key request from the 1Password menu bar item.

# Needs Raycast in System Settings → Privacy & Security → Accessibility.

# Clicking the menu bar item, and the SSH item that opens the approval prompt,
# blocks System Events until the menu or prompt closes. Fire both clicks
# without waiting and restart System Events afterwards to unblock it.
on unblockSystemEvents()
	-- Wait until it has exited: an event sent to an instance that is still
	-- shutting down never gets a reply, and hangs the script.
	do shell script "killall -9 'System Events' 2>/dev/null; for i in $(seq 100); do pgrep -qf 'CoreServices/System Events.app' || break; sleep 0.01; done; true"
end unblockSystemEvents

ignoring application responses
	tell application "System Events" to tell process "1Password" to click menu bar item 1 of menu bar 2
end ignoring
unblockSystemEvents()

set sshIndex to 0
set menuReady to false
tell application "System Events" to tell process "1Password"
	-- Poll for the menu instead of a fixed delay. With no request pending,
	-- 1Password stops answering while its menu is open, so stop at the first
	-- query that times out rather than retrying it.
	repeat 25 times
		try
			with timeout of 1 second
				if exists menu 1 of menu bar item 1 of menu bar 2 then
					set menuReady to true
					exit repeat
				end if
			end timeout
		on error number errNum
			if errNum is -1712 then exit repeat -- AppleEvent timed out
		end try
		delay 0.02
	end repeat
end tell

if not menuReady then
	-- System Events stays unresponsive while this menu is open, so post Esc
	-- straight to the HID event stream to close it, then free System Events.
	do shell script "osascript -l JavaScript -e 'ObjC.import(\"CoreGraphics\"); [true, false].forEach(d => $.CGEventPost(0, $.CGEventCreateKeyboardEvent(null, 53, d)))'"
	unblockSystemEvents()
	return "No pending SSH request"
end if

tell application "System Events" to tell process "1Password"
	-- Fetch all names in one Accessibility call; a whose-filter queries each item.
	with timeout of 2 seconds
		set itemNames to name of every menu item of menu 1 of menu bar item 1 of menu bar 2
	end timeout
	repeat with i from 1 to count of itemNames
		set itemName to item i of itemNames
		if itemName is not missing value and itemName contains "SSH" then
			set sshIndex to i
			exit repeat
		end if
	end repeat
	if sshIndex is 0 then
		key code 53 -- Esc: no pending request, close the menu
		return "No pending SSH request"
	end if
end tell

ignoring application responses
	tell application "System Events" to tell process "1Password" to click menu item sshIndex of menu 1 of menu bar item 1 of menu bar 2
end ignoring
delay 0.1
unblockSystemEvents()
