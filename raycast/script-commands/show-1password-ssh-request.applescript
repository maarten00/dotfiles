#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Show 1Password SSH Request
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🔑
# @raycast.description Open the pending SSH key request from the 1Password menu bar item.

# Needs Raycast in System Settings → Privacy & Security → Accessibility.

# Clicking a menu bar item blocks System Events until the menu closes (seconds),
# so fire the click without waiting and restart System Events to unblock it.
ignoring application responses
	tell application "System Events" to tell process "1Password" to click menu bar item 1 of menu bar 2
end ignoring
do shell script "killall 'System Events' || true"

tell application "System Events" to tell process "1Password"
	-- Poll for the menu instead of a fixed delay; gives up after ~1s. The try
	-- covers System Events still relaunching.
	repeat 50 times
		try
			if exists menu 1 of menu bar item 1 of menu bar 2 then exit repeat
		end try
		delay 0.02
	end repeat
	set sshMenu to menu 1 of menu bar item 1 of menu bar 2
	-- Fetch all names in one Accessibility call; a whose-filter queries each item.
	set itemNames to name of every menu item of sshMenu
	repeat with i from 1 to count of itemNames
		set itemName to item i of itemNames
		if itemName is not missing value and itemName contains "SSH" then
			click menu item i of sshMenu
			return
		end if
	end repeat
	key code 53 -- Esc: no pending request, close the menu
	return "No pending SSH request"
end tell
