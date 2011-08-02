--      This program is free software; you can redistribute it and/or modify
--      it under the terms of the GNU General Public License as published by
--      the Free Software Foundation; either version 2 of the License, or
--      (at your option) any later version.
--      
--      This program is distributed in the hope that it will be useful,
--      but WITHOUT ANY WARRANTY; without even the implied warranty of
--      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--      GNU General Public License for more details.
--      
--      You should have received a copy of the GNU General Public License
--      along with this program; if not, write to the Free Software
--      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
--      MA 02110-1301, USA.
--      
require "simplexml"

api_key = "8298753439c65230b5e89c36cf5794f5"
base_url = "http://api.musixmatch.com/ws/1.1/"

-- start of VLC required functions
dlg = nil
title = nil
artist = nil
lyric = nil

-- VLC Extension Descriptor
function descriptor()
	return {
		title = "musiXmatch lyrics";
		version = "0.1";
		author = "Giorgio Salluzzo <giorgio@musixmatch.com>";
		url = 'http://musixmatch.com';
		description = "<center><b>Lyrics Plugin</b></center>"
			.. "<br /><b>Gets the lyrics using musiXmatch.com API</b>"
			.. "<br /><b>(Based on the script made by Jean-Philippe Andre)</b>";
		shortdesc = "Get the lyrics from musixmatch.com";
		capabilities = { "input-listener"; "meta-listener" }
	}
end

-- Function triggered when the extension is activated
function activate()
	vlc.msg.dbg(_VERSION)
	vlc.msg.dbg("[Lyrics] Activating")
	show_dialog()
	return true
end

-- Function triggered when the extension is deactivated
function deactivate()
	close()
	vlc.msg.dbg("[Lyrics] Deactivated")
	return true
end

function new_dialog(title)
	dlg=vlc.dialog(title)
end

-- Function triggered when the dialog is closed
function close()
	reset_variables()
	vlc.deactivate()
end

function show_dialog()
	if dlg == nil then
		new_dialog("musiXmatch lyrics")
	end

	-- column, row, col_span, row_span, width, height

	dlg:add_label("Title:", 1, 1, 1, 1)
	title = dlg:add_text_input(get_title(), 2, 1, 3, 1)

	dlg:add_label("Artist:", 1, 2, 1, 1)
	artist = dlg:add_text_input(get_artist(), 2, 2, 3, 1)
	
	dlg:add_button("Update", update_metas, 1, 3, 1, 1)
	dlg:add_button("Get Lyrics", click_lyrics_button, 2, 3, 2, 1)
	dlg:add_button("Close", close, 4, 3, 1, 1)
	lyric = dlg:add_html("", 1,4,4,4)
	return true
end

-- Resets Dialog
function reset_variables()
	dlg = nil
	title = nil
	artist = nil
	lyric = nil
end

-- Updates Input Fields
function update_metas()
	title:set_text(get_title())
	artist:set_text(get_artist())

	dlg:update()
	return true
end
-- end of VLC functions

function get_lyrics(title_x, artist_x)
	title_x = trim(title_x)
	artist_x = trim(artist_x)

	title_x = string.gsub(title_x, " ", "+")
	artist_x = string.gsub(artist_x, " ", "+")

	local match = base_url.."matcher.track.get?apikey="..api_key.."&format=xml&q_artist="..artist_x.."&q_track="..title_x

	local track_id = 0
	local lyrics_id = 0

	local tree = simplexml.parse_url(match)

	simplexml.add_name_maps(tree)
	local body = tree.children_map['body'][1]

	for _, item in ipairs(body.children) do
		if(item.name == 'track') then
			simplexml.add_name_maps(item)
			track_id=item.children_map["track_id"][1].children[1]
			lyrics_id=item.children_map["lyrics_id"][1].children[1]
		end
	end

	if tonumber(lyrics_id) < 1 then
		return ""
	end

	local get = base_url.."track.lyrics.get?apikey="..api_key.."&format=xml&track_id="..track_id

	local lyrics_body = ""
	local lyrics_copyright = ""
	local pixel_tracking_url = ""

        local tree = simplexml.parse_url(get)

        simplexml.add_name_maps(tree)
        local body = tree.children_map['body'][1]

	for _, item in ipairs(body.children) do
		if(item.name == "lyrics") then
			simplexml.add_name_maps(item)
			lyrics_body=item.children_map["lyrics_body"][1].children[1]
			lyrics_copyright=item.children_map["lyrics_copyright"][1].children[1]
			pixel_tracking_url=item.children_map["pixel_tracking_url"][1].children[1]
		end
	end

	local pixel = vlc.stream(pixel_tracking_url)
	
	local lyrics = lyrics_body .. "\n\n\n<b>" .. lyrics_copyright .. "</b>"

	return string.gsub(lyrics, "\n", "<br>")
end

function click_lyrics_button()
	lyric:set_text("LOADING...")
	dlg:update()
	
	local songtitle = title:get_text()
	local songartist = artist:get_text()

	local lyric_string = get_lyrics(songtitle, songartist)
	if lyric_string=="" or lyric_string==nil then
		lyric:set_text("<i>Track not found</i>")
		dlg:update()
		return false
	end

	lyric:set_text(lyric_string)
	dlg:update()
	return true
end

-- Get clean title from filename
function get_title()
	local item = vlc.item or vlc.input.item()
	if not item then
		return ""
	end
	local metas = item:metas()
	if metas["title"] then
		return metas["title"]
	else
		local filename = string.gsub(item:name(), "^(.+)%.%w+$", "%1")
		return trim(filename or item:name())
	end
end

-- Get clean artist from filename
function get_artist()
	local item = vlc.item or vlc.input.item()
	if not item then
		return ""
	end
	local metas = item:metas()
	if metas["artist"] then
		return metas["artist"]
	else
		return ""
	end
end

-- Remove leading and trailing spaces
function trim(str)
	if not str then return "" end
	return string.gsub(str, "^%s*(.-)%s*$", "%1")
end



