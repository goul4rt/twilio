# Aprovação de entradas: neste Mac (o principal), pergunta se libera o Twilio aberto em outro computador.
# Roda sempre (LaunchAgent). Uso manual: python3 aprova.py logs  -> mostra o histórico da VPS.
import json, os, subprocess, sys, time, urllib.request

URL = "https://disp.ogoulart.dev"
CHAVE = open(os.path.expanduser("~/Library/Application Support/AjustesTela/chave-admin")).read().strip()


def api(caminho, dados=None):
    r = urllib.request.Request(URL + caminho, data=None if dados is None else json.dumps(dados).encode(),
                               headers={"Authorization": "Bearer " + CHAVE, "Content-Type": "application/json", "User-Agent": "ajustes-tela"})
    return json.load(urllib.request.urlopen(r, timeout=15))


def pergunta(p):
    hora = time.strftime("%d/%m %H:%M", time.localtime(p["criado"]))
    texto = f'Login duplo detectado.\n\nDispositivo: {p["nome"]}\nIP: {p["ip"]}\nHora: {hora}\n\nAutorizar a entrada?'
    r = subprocess.run(["osascript", "-e", f'display dialog {json.dumps(texto)} with title "Twilio" buttons {{"Negar", "Autorizar"}} '
                        'default button "Negar" cancel button "Negar" with icon caution giving up after 300'], capture_output=True, text=True)
    return "button returned:Autorizar" in r.stdout and "gave up:true" not in r.stdout  # sem resposta em 5 min = nega


if sys.argv[1:] == ["logs"]:
    for l in api("/logs"):
        print(l["t"], l["ev"].ljust(8), l.get("nome", ""), l.get("ip", ""))
    sys.exit()

vistos = set()
while True:
    try:
        for p in api("/pendentes"):
            if p["id"] not in vistos:
                vistos.add(p["id"])
                api(f'/decidir/{p["id"]}', {"ok": pergunta(p)})
    except Exception:
        pass  # VPS fora do ar ou sem internet: tenta de novo
    time.sleep(5)
