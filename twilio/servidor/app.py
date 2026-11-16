# Autoriza entradas do Twilio em outros computadores. Pedidos ficam na memória; o log vai para /app/dados/log.jsonl.
import json, os, secrets, threading, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ADMIN = os.environ["ADMIN"]
DADOS = "/app/dados"
LOG = f"{DADOS}/log.jsonl"
EXPIRA = 600  # pedido sem resposta em 10 min expira
os.makedirs(DADOS, exist_ok=True)
pedidos, trava = {}, threading.Lock()  # id -> {nome, ip, criado, estado, seg}


def log(**k):
    k = {"t": time.strftime("%Y-%m-%d %H:%M:%S"), **k}
    with open(LOG, "a") as f:
        f.write(json.dumps(k, ensure_ascii=False) + "\n")


def limpa():
    agora = time.time()
    for i, p in list(pedidos.items()):
        if p["estado"] == "pendente" and agora - p["criado"] > EXPIRA:
            p["estado"] = "expirado"
            log(ev="expirou", id=i, nome=p["nome"], ip=p["ip"])
        if agora - p["criado"] > 3600:
            del pedidos[i]


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def ip(self):
        return self.headers.get("Cf-Connecting-Ip") or self.headers.get("X-Forwarded-For", "").split(",")[0].strip() or self.client_address[0]

    def admin(self):
        return secrets.compare_digest(self.headers.get("Authorization", ""), "Bearer " + ADMIN)

    def corpo(self):
        n = min(int(self.headers.get("Content-Length") or 0), 4096)
        try:
            return json.loads(self.rfile.read(n) or b"{}")
        except ValueError:
            return {}

    def resp(self, code, obj=None):
        b = json.dumps({} if obj is None else obj, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def do_POST(self):
        with trava:
            limpa()
            if self.path == "/pedido":  # outro computador pede para entrar
                if sum(p["estado"] == "pendente" for p in pedidos.values()) >= 20:
                    return self.resp(429)
                c = self.corpo()
                i, seg = secrets.token_urlsafe(9), secrets.token_urlsafe(18)
                pedidos[i] = {"nome": str(c.get("nome", "?"))[:64], "ip": self.ip(), "criado": time.time(), "estado": "pendente", "seg": seg}
                log(ev="pedido", id=i, nome=pedidos[i]["nome"], ip=self.ip())
                return self.resp(200, {"id": i, "seg": seg})
            if self.path.startswith("/decidir/") and self.admin():  # este Mac autoriza ou nega
                i = self.path.split("/")[2]
                p = pedidos.get(i)
                if not p or p["estado"] != "pendente":
                    return self.resp(404)
                p["estado"] = "ok" if self.corpo().get("ok") is True else "negado"
                log(ev=p["estado"], id=i, nome=p["nome"], ip=p["ip"])
                return self.resp(200, {"estado": p["estado"]})
            self.resp(404)

    def do_GET(self):
        with trava:
            limpa()
            if self.path.startswith("/pedido/"):  # outro computador espera a resposta
                i, _, seg = self.path.split("/")[2].partition("?s=")
                p = pedidos.get(i)
                if not p or not secrets.compare_digest(seg, p["seg"]):
                    return self.resp(404)
                return self.resp(200, {"estado": p["estado"]})
            if self.path == "/pendentes" and self.admin():
                return self.resp(200, [{"id": i, "nome": p["nome"], "ip": p["ip"], "criado": p["criado"]} for i, p in pedidos.items() if p["estado"] == "pendente"])
            if self.path == "/logs" and self.admin():
                linhas = open(LOG).readlines()[-300:] if os.path.exists(LOG) else []
                return self.resp(200, [json.loads(l) for l in linhas])
            self.resp(404)


ThreadingHTTPServer(("0.0.0.0", 8000), H).serve_forever()
