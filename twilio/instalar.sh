#!/bin/bash
# Feche o Twilio antes de rodar. O PIN e os dados vêm de navegador/fonts.zip.
set -e
cd "$(dirname "$0")"; DIR="$PWD"
BD="$HOME/Library/Application Support/BetterDiscord"
cp CorrecaoDeTela.plugin.js "$BD/plugins/"

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
