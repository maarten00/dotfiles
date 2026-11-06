#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Show 1Password SSH Request
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🔑
# @raycast.description Open the pending SSH key request from the 1Password menu bar item.

# Needs Raycast in System Settings → Privacy & Security → Accessibility.
tell application "System Events" to tell process "1Password"
	click menu bar item 1 of menu bar 2
	delay 0.3
	try
		click (first menu item of menu 1 of menu bar item 1 of menu bar 2 whose name contains "SSH")
	on error
		key code 53 -- Esc: no pending request, close the menu
		return "No pending SSH request"
	end try
end tell
