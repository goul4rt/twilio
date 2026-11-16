#!/bin/bash
# Vigia do Twilio: se ele está aberto e o plugin não dá sinal de vida, o BetterDiscord caiu
# (atualização do Discord). Fecha o Twilio na hora e avisa, para nada aparecer sem a trava e sem os filtros.
HB="$HOME/Library/Application Support/BetterDiscord/plugins/Batimento.config.json"
APP="^[^ ]*Twilio\.app/Contents/MacOS/Discord"   # só o executável do Twilio, não qualquer comando que cite o caminho
TOLERANCIA=12   # segundos de Twilio aberto até o primeiro sinal (medido: ~5 s)
SILENCIO=180    # sem sinal por mais que isso no meio do uso = plugin parou (folga para janela minimizada)

idade() { ps -o etime= -p "$1" | tr -d ' ' | awk -F'[-:]' '{n=NF; s=$n+0; if(n>1)s+=$(n-1)*60; if(n>2)s+=$(n-2)*3600; if(n>3)s+=$(n-3)*86400; print s}'; }
fecha() {
  pkill -f "^[^ ]*Twilio\.app/Contents/"
  osascript -e 'display alert "Twilio fechado" message "A proteção não carregou (o Discord deve ter se atualizado). Abra o instalador do BetterDiscord, clique em Repair e abra o Twilio de novo." as critical' >/dev/null 2>&1 &
  sleep 5
}

base=$(date +%s); volta=$base
while sleep 2; do
  agora=$(date +%s)
  [ $((agora - volta)) -gt 10 ] && base=$agora   # Mac dormiu: recomeça a contagem do silêncio
  volta=$agora
  pid=$(pgrep -of "$APP") || continue
  vida=$(idade "$pid"); [ -z "$vida" ] && continue
  inicio=$((agora - vida))
  ult=$(stat -f %m "$HB" 2>/dev/null || echo 0)
  if [ "$vida" -ge "$TOLERANCIA" ] && [ "$ult" -lt "$inicio" ]; then fecha; continue; fi   # abriu e o plugin nunca deu sinal
  ref=$(( ult > base ? ult : base )); ref=$(( ref > inicio ? ref : inicio ))
  [ $((agora - ref)) -gt "$SILENCIO" ] && fecha                                            # parou de dar sinal
done
