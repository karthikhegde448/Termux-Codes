​1. Preparing the Environment
​Before creating the file, make sure your Termux has the necessary tools and storage access.
​Grant Storage Access: (So the bot can save to your phone's Download folder)
termux-setup-storage
​Install Python and Nano:
pkg update && pkg upgrade
pkg install python nano
​Install Libraries:
pip install pyTelegramBotAPI yt-dlp
​2. Creating and Editing the Bot
​We will use Nano, which is a simple text editor inside the terminal.
​Create the file:
Type this command to open a new blank file named bot_dl.py:
nano bot_dl.py
​Paste your code:
Copy the code longest code here below mentioned as bot_dl.py code. In Termux, you usually long-press the screen and select Paste.
​Saving and Exiting (The "Secret" Keys):
Nano uses Ctrl (Control) shortcuts shown at the bottom of the screen.
​To Save: Press Ctrl + O (The letter O for "Output"), then press Enter to confirm the filename.
​To Exit: Press Ctrl + X.
​3. Running and Managing the Bot
​Once you are back at the command prompt (the $ sign), use these commands:

Start the Bot 
python bot_dl.py

Stop the Bot 
Press Ctrl + C (This kills the process)

Check Files 
ls (Lists all files in your current folder)

Delete the Bot rm bot_dl.py (Be careful with this one!)

Keep Bot Running termux-wake-lock (Prevents Android from killing the bot when screen is off)


bot_dl.py code(The main Code):Paste this in 
the nano bot_dl.py




import telebot
from telebot.types import InlineKeyboardMarkup, InlineKeyboardButton
import subprocess
import json
import os
import re

# --- CONFIGURATION ---
API_TOKEN = 'YOUR_NEW_BOT_TOKEN' 
MY_ID = 8607284230 
DOWNLOAD_PATH = "/sdcard/Download/"

bot = telebot.TeleBot(API_TOKEN)
user_data = {}

def sanitize_name(name):
    if not name: return "YouTube_Downloads"
    return re.sub(r'[\\/*?:"<>|]', "", name).strip()

def get_metadata(url):
    try:
        cmd = ['yt-dlp', '--dump-json', '--playlist-items', '1', url]
        res = subprocess.run(cmd, capture_output=True, text=True)
        
        if not res.stdout:
            return {'heights': [360, 480, 720, 1080], 'folder_name': 'Playlist'}
            
        data = json.loads(res.stdout.split('\n')[0])
        formats = data.get('formats', [])
        heights = sorted(list(set(f.get('height') for f in formats if f.get('height') and f.get('height') > 144)))
        
        title = data.get('playlist_title') if data.get('playlist_title') else None
        
        return {
            'heights': heights if heights else [360, 480, 720, 1080],
            'folder_name': sanitize_name(title) if title else None
        }
    except Exception:
        return {'heights': [360, 480, 720, 1080], 'folder_name': 'Playlist'}

@bot.message_handler(func=lambda message: message.from_user.id == MY_ID)
def handle_link(message):
    url = message.text.strip()
    if "youtube.com" in url or "youtu.be" in url:
        bot.send_message(message.chat.id, "🔍 Fetching link details...")
        meta = get_metadata(url)
        
        user_data[message.chat.id] = {
            'url': url,
            'folder_name': meta['folder_name'],
            'heights': meta['heights'],
            'trim': None,
            'range': None
        }
        
        markup = InlineKeyboardMarkup()
        markup.add(InlineKeyboardButton("🎵 Audio", callback_data="main_audio"))
        markup.add(InlineKeyboardButton("🎬 Video", callback_data="main_video"))
        markup.add(InlineKeyboardButton("✂️ Trim", callback_data="main_trim"))
        markup.add(InlineKeyboardButton("🔢 Select Range", callback_data="main_range"))
        
        bot.send_message(message.chat.id, "Select an option:", reply_markup=markup)
    else:
        bot.send_message(message.chat.id, "Please send a valid YouTube link.")

@bot.callback_query_handler(func=lambda call: call.data.startswith('main_'))
def handle_main(call):
    chat_id = call.message.chat.id
    action = call.data.split('_')[1]
    
    if action == "audio":
        start_download(chat_id, "audio")
    elif action == "video":
        show_qualities(chat_id)
    elif action == "trim":
        msg = bot.send_message(chat_id, "✂️ Enter time limit (e.g., `00:01:00-00:02:30`):")
        bot.register_next_step_handler(msg, lambda m: set_extra(m, 'trim'))
    elif action == "range":
        msg = bot.send_message(chat_id, "🔢 Enter playlist range (e.g., `1-5`):")
        bot.register_next_step_handler(msg, lambda m: set_extra(m, 'range'))

def set_extra(message, key):
    chat_id = message.chat.id
    user_data[chat_id][key] = message.text.strip()
    
    markup = InlineKeyboardMarkup()
    markup.add(InlineKeyboardButton("🎵 Audio", callback_data="sub_audio"))
    markup.add(InlineKeyboardButton("🎬 Video", callback_data="sub_video"))
    bot.send_message(chat_id, f"✅ {key.capitalize()} set to {message.text}. Choose format:", reply_markup=markup)

@bot.callback_query_handler(func=lambda call: call.data.startswith('sub_'))
def handle_sub(call):
    chat_id = call.message.chat.id
    choice = call.data.split('_')[1]
    
    if choice == "audio":
        start_download(chat_id, "audio")
    else:
        show_qualities(chat_id)

def show_qualities(chat_id):
    qualities = user_data[chat_id]['heights']
    markup = InlineKeyboardMarkup()
    for q in qualities:
        markup.add(InlineKeyboardButton(f"{q}p", callback_data=f"dl_{q}"))
        
    bot.send_message(chat_id, "✅ Select Video Quality:", reply_markup=markup)

@bot.callback_query_handler(func=lambda call: call.data.startswith('dl_'))
def handle_final_dl(call):
    quality = call.data.split('_')[1]
    start_download(call.message.chat.id, "video", quality)

def start_download(chat_id, mode, quality=None):
    d = user_data[chat_id]
    
    # --- FOLDER LOGIC (WITH RANGE) ---
    save_path = DOWNLOAD_PATH
    if d['folder_name']:
        folder_name = d['folder_name']
        
        # If a range was selected, append it to the folder name
        if d['range']:
            clean_range = sanitize_name(d['range'])
            folder_name = f"{folder_name} {clean_range}"
            
        save_path = os.path.join(DOWNLOAD_PATH, folder_name)
        if not os.path.exists(save_path):
            os.makedirs(save_path, exist_ok=True)
            
    output_template = os.path.join(save_path, "%(title)s.%(ext)s")
    
    # --- COMMAND CONSTRUCTION ---
    cmd = [
        'yt-dlp', 
        '--yes-playlist', 
        '--force-overwrites', 
        '-o', output_template
    ]
    
    if d['range']: cmd.extend(['--playlist-items', d['range']])
    if d['trim']: cmd.extend(['--download-sections', f"*{d['trim']}"])
    
    if mode == "audio":
        cmd.extend(['-f', 'bestaudio/best', '-x', '--audio-format', 'mp3'])
        bot.send_message(chat_id, f"📥 Downloading Audio...\nFolder: {os.path.basename(save_path)}")
    else:
        cmd.extend(['-f', f'bestvideo[height<={quality}]+bestaudio/best', '--merge-output-format', 'mp4'])
        bot.send_message(chat_id, f"📥 Downloading Video ({quality}p)...\nFolder: {os.path.basename(save_path)}")
    
    cmd.append(d['url'])
    
    try:
        # Removed capture_output=True so Termux shows the live progress!
        subprocess.run(cmd, check=True)
        bot.send_message(MY_ID, "✅ Download Complete!")
    except subprocess.CalledProcessError:
        bot.send_message(MY_ID, "❌ Download Error! Check Termux screen for details.")
    except Exception as e:
        bot.send_message(MY_ID, f"❌ Script Crash: {e}")
        
    # Reset states for the next link
    user_data[chat_id]['trim'] = None
    user_data[chat_id]['range'] = None

print("--- Bot is ONLINE ---")
bot.infinity_polling()















Creating an alias for the above cmd

Open your configuration file:
nano ~/.bashrc

​Find the line you wrote earlier and 
change start to y:
alias y='cd /sdcard/Download && python bot_dl.py'

​Save and Exit:
Press Ctrl + O, then Enter, then Ctrl + X.

​Refresh the shell:
source ~/.bashrc








Quick Reminder: If you ever get an error saying yt-dlp is out of date, just run pip install -U yt-dlp in Termux to update it
