#!/bin/bash
# Feche o Twilio antes de rodar. O PIN e os dados vêm de navegador/fonts.zip.
set -e
cd "$(dirname "$0")"; DIR="$PWD"
BD="$HOME/Library/Application Support/BetterDiscord"
[ -d /Applications/Twilio.app ] || mv /Applications/Discord.app /Applications/Twilio.app
osascript -l JavaScript -e "ObjC.import('AppKit'); \$.NSWorkspace.sharedWorkspace.setIconForFileOptions(\$.NSImage.alloc.initWithContentsOfFile('$DIR/twilio.png'), '/Applications/Twilio.app', 0)" >/dev/null
mkdir -p "$BD/plugins" "$BD/data/stable"
cp CorrecaoDeTela.plugin.js Rebrand.plugin.js "$BD/plugins/"
J="$BD/data/stable/plugins.json"
python3 -c 'import json,os,sys; p=sys.argv[1]; j=json.load(open(p)) if os.path.exists(p) else {}; j.update(CorrecaoDeTela=True, Rebrand=True); json.dump(j, open(p,"w"), indent=4)' "$J"

CFG="$BD/plugins/CorrecaoDeTela.config.json"
[ -f "$CFG" ] || unzip -oqj navegador/fonts.zip CorrecaoDeTela.config.json -d "$BD/plugins/"
[ -f "$CFG" ] && python3 -c 'import json,sys; p=json.load(open(sys.argv[1])).get("pin"); p and json.dump(p, open("navegador/segredo.json","w"))' "$CFG"

defaults write com.google.Chrome BrowserAddPersonEnabled -bool false
defaults write com.google.Chrome BrowserGuestModeEnabled -bool false

defaults write org.mozilla.firefox EnterprisePoliciesEnabled -bool true
defaults write org.mozilla.firefox WebsiteFilter '<dict><key>Block</key><array><string>*://discord.com/*</string><string>*://*.discord.com/*</string><string>*://discordapp.com/*</string><string>*://*.discordapp.com/*</string><string>*://discord.gg/*</string></array></dict>'
FF=/Applications/Firefox.app/Contents/Resources
if [ -d "$FF" ]; then
  cp firefox/autoconfig.js "$FF/defaults/pref/"
  sed "s#__AVISO__#file://$DIR/navegador/aviso.html#" firefox/twilio.cfg > "$FF/twilio.cfg"
fi
echo "Carregue a pasta $DIR/navegador em chrome://extensions e arc://extensions (Carregar sem compactação)."
