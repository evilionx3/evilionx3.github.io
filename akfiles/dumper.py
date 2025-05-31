import os
import requests
from urllib.parse import urlparse

urls = [
    "https://raw.githubusercontent.com/2dgeneralspam1/scripts-and-stuff/master/scripts/LoadstringypVvhJBq4QNz",
    "https://ichfickdeinemutta.pages.dev/aimbot.lua",
    "https://ichfickdeinemutta.pages.dev/AKHUB.lua",
    "https://ichfickdeinemutta.pages.dev/Baseplate.lua",
    "https://raw.githubusercontent.com/ZLens/3v2g784tb7r63vtavs/refs/heads/main/helloworld.lua",
    "https://ichfickdeinemutta.pages.dev/FOV.lua",
    "https://ichfickdeinemutta.pages.dev/lagserver.lua",
    "https://ichfickdeinemutta.pages.dev/fitchanger.lua",
    "https://ichfickdeinemutta.pages.dev/Bodysnake.lua",
    "https://ichfickdeinemutta.pages.dev/Animcopy.lua",
    "https://ichfickdeinemutta.pages.dev/animrecorder.lua",
    "https://ichfickdeinemutta.pages.dev/Bodyletter.lua",
    "https://ichfickdeinemutta.pages.dev/vccontroller.lua",
    "https://ichfickdeinemutta.pages.dev/permdeath.lua",
    "https://ichfickdeinemutta.pages.dev/Ad.lua",
    "https://ichfickdeinemutta.pages.dev/ftp.lua",
    "https://ichfickdeinemutta.pages.dev/sizechanger.lua",
    "https://ichfickdeinemutta.pages.dev/annoynearest.lua",
    "https://ichfickdeinemutta.pages.dev/limborbit.lua",
    "https://ichfickdeinemutta.pages.dev/annoyserver.lua",
    "https://ichfickdeinemutta.pages.dev/trip.lua",
    "https://ichfickdeinemutta.pages.dev/pickuplines.lua",
    "https://ichfickdeinemutta.pages.dev/AKbypasser.lua",
    "https://raw.githubusercontent.com/Eazvy/public-scripts/main/Universal_Animations_Emotes.lua",
    "https://ichfickdeinemutta.pages.dev/Animlogger.lua",
    "https://ichfickdeinemutta.pages.dev/Antiall.lua",
    "https://ichfickdeinemutta.pages.dev/antiall2.lua",
    "https://ichfickdeinemutta.pages.dev/antiall3.lua",
    "https://ichfickdeinemutta.pages.dev/autoreactivatevc.lua",
    "https://ichfickdeinemutta.pages.dev/Reversee.lua",
    "https://ichfickdeinemutta.pages.dev/antibang.lua",
    "https://raw.githubusercontent.com/xSejker/AntilagFixedd/main/README.md",
    "https://ichfickdeinemutta.pages.dev/antilogger.lua",
    "https://ichfickdeinemutta.pages.dev/Anti%20Headsit.lua",
    "https://ichfickdeinemutta.pages.dev/Antikick.lua",
    "https://ichfickdeinemutta.pages.dev/Antifling.lua",
    "https://ichfickdeinemutta.pages.dev/Antivoid.lua",
    "https://ichfickdeinemutta.pages.dev/autogrmr.lua",
    "https://ichfickdeinemutta.pages.dev/cspy.lua",
    "https://ichfickdeinemutta.pages.dev/Bodyinvis.lua",
    "https://raw.githubusercontent.com/Guerric9018/chatbothub/main/ChatbotHub",
    "https://ichfickdeinemutta.pages.dev/chatdraw.lua",
    "https://ichfickdeinemutta.pages.dev/Chatlogs.lua",
    "https://raw.githubusercontent.com/Damian-11/quizbot/master/quizbot.luau",
    "https://ichfickdeinemutta.pages.dev/Chattroll.lua",
    "https://ichfickdeinemutta.pages.dev/clearcmd.lua",
    "https://ichfickdeinemutta.pages.dev/getoutmyinv.lua",
    "https://ichfickdeinemutta.pages.dev/Dropkick.lua",
    "https://ichfickdeinemutta.pages.dev/Emotes.lua",
    "https://raw.githubusercontent.com/JejcoTwiUmYQXhBpKMDl/emoji/main/emo.lua",
    "https://ichfickdeinemutta.pages.dev/Errornotif.lua",
    "https://ichfickdeinemutta.pages.dev/facefuck.lua",
    "https://ichfickdeinemutta.pages.dev/fling.lua",
    "https://raw.githubusercontent.com/insanedude59/MiscReleases/main/Roblox/UWPFPSBooster.lua",
    "https://ichfickdeinemutta.pages.dev/Freecam.lua",
    "https://ichfickdeinemutta.pages.dev/Hug.lua",
    "https://ichfickdeinemutta.pages.dev/Invis.lua",
    "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source",
    "https://ichfickdeinemutta.pages.dev/Jerk.lua",
    "https://ichfickdeinemutta.pages.dev/loopclearchat.lua",
    "https://ichfickdeinemutta.pages.dev/Micupcombo.lua",
    "https://ichfickdeinemutta.pages.dev/mutenonfriends.lua",
    "https://ichfickdeinemutta.pages.dev/Nofriends.lua",
    "https://ichfickdeinemutta.pages.dev/Ndsgodmode.lua",
    "https://ichfickdeinemutta.pages.dev/oof.lua",
    "https://ichfickdeinemutta.pages.dev/gimmetools.lua",
    "https://ichfickdeinemutta.pages.dev/vcbyp.lua",
    "https://ichfickdeinemutta.pages.dev/Remotechecker.lua",
    "https://ichfickdeinemutta.pages.dev/Sfly.lua",
    "https://ichfickdeinemutta.pages.dev/serverhop.lua",
    "https://ichfickdeinemutta.pages.dev/Shiftlock.lua",
    "https://ichfickdeinemutta.pages.dev/shlow.lua",
    "https://ichfickdeinemutta.pages.dev/shmost.lua",
    "https://ichfickdeinemutta.pages.dev/Sneak.lua",
    "https://ichfickdeinemutta.pages.dev/stopglide.lua",
    "https://ichfickdeinemutta.pages.dev/touchfling.lua",
    "https://ichfickdeinemutta.pages.dev/touchmanager.lua",
    "https://ichfickdeinemutta.pages.dev/TPtoplayer.lua",
    "https://ichfickdeinemutta.pages.dev/unanchor%20fling.lua",
    "https://raw.githubusercontent.com/unified-naming-convention/NamingStandard/refs/heads/main/UNCCheckEnv",
    "https://ichfickdeinemutta.pages.dev/Vcbypass.lua",
    "https://ichfickdeinemutta.pages.dev/voidoof.lua",
    "https://ichfickdeinemutta.pages.dev/Walkonair.lua",
    "https://ichfickdeinemutta.pages.dev/Walkonvoid.lua",
    "https://ichfickdeinemutta.pages.dev/ps.lua",
    "https://ichfickdeinemutta.pages.dev/instantRE.lua"
]

for url in urls:
    try:
        filename = os.path.basename(url.split("?")[0])
        if not filename:
            print(f"Skipping (no filename): {url}")
            continue

        response = requests.get(url)
        response.raise_for_status()

        with open(filename, "wb") as f:
            if filename.endswith((".lua", ".txt", ".json", ".luau")):
                f.write(f"-- {url}\n".encode())
            f.write(response.content)

        print(f"Downloaded: {filename}")
    except Exception as e:
        print(f"Failed to download {url}: {e}")
