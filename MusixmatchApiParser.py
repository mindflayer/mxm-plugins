#       This program is free software; you can redistribute it and/or modify
#       it under the terms of the GNU General Public License as published by
#       the Free Software Foundation; either version 2 of the License, or
#       (at your option) any later version.
#       
#       This program is distributed in the hope that it will be useful,
#       but WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#       GNU General Public License for more details.
#       
#       You should have received a copy of the GNU General Public License
#       along with this program; if not, write to the Free Software
#       Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#       MA 02110-1301, USA.
#       

import json
try:
    import urllib.request as urllib2
except ImportError:
    import urllib2
try:
    from urllib import urlencode
except ImportError:
    from urllib.parse import urlencode

def fetch(url):
    return json.loads(urllib2.urlopen(url).read().decode('utf-8'))

API_KEY = "8298753439c65230b5e89c36cf5794f5"
API_VERSION = "1.1"
API_BASE_URL = "http://api.musixmatch.com/ws/%s" % API_VERSION

class Track:
    def __init__(self, artist, track):
        
        self.__p = PyLyrix()
        track = self.__p.matcher_track_get(artist, track)
        
        if track:
            self.__setter(track)
        else:
            self = None

    def __setter(self, d):
        for e in d:
            setattr(self, e, d[e])

    def get_lyrics(self):
        lyrics = self.__p.track_lyrics_get(self.track_id)
        
        if not lyrics:
            return None

        self.__setter(lyrics)
        
        return self.lyrics_body + "\n\n" + self.lyrics_copyright


class PyLyrix:

    def __init__(self, apikey=API_KEY, api_version=API_VERSION):
        self.baseurl = API_BASE_URL
        self.params = {
                        'apikey' : apikey,
                        'format' : 'json'
                      }

    def __call(self, action, params):
        params = urlencode([(k, params[k]) for k in params if params[k]])
        return fetch("%s/%s?%s" % (self.baseurl, action, params))

    def matcher_track_get(self, artist, track, action="matcher.track.get"):
        params = ({
                    'q_artist' : artist.replace(' ', '+').encode('utf-8'),
                    'q_track'  : track.replace(' ', '+').encode('utf-8'),
        })
        params.update(self.params)

        jtrack = self.__call(action, params)
        try:
            return jtrack['message']['body']['track']
        except:
            return None

        return jtrack

    def track_lyrics_get(self, track_id, action="track.lyrics.get"):
        params = ({
            'track_id' : track_id,
        })
        params.update(self.params)

        jlyrics = self.__call(action, params)
        try:
            jlyrics = jlyrics['message']['body']['lyrics']
        except:
            return None

        return jlyrics

class MusixmatchApiParser(object):
    def __init__(self, artist, title):
        self.artist = artist
        self.title = title

    def search(self, callback, *data):
        t = Track(self.artist, self.title)
        
        if not t:
            return callback(None, *data)

        try:
            urllib2.urlopen(t['pixel_tracking_url']).read()
        except:
            pass

        return callback(t.get_lyrics(), *data)
