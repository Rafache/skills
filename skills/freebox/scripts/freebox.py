#!/usr/bin/env python3
"""
CLI Freebox OS pour l'AuBox
Permet le contrôle et le diagnostic de la Freebox Pop / Delta / Revolution via son API locale.
"""

import argparse
import hashlib
import hmac
import json
import os
import sys
import time
import urllib.error
import urllib.request

CONFIG_DIR = os.path.expanduser("~/.config/freebox")
CONFIG_FILE = os.path.join(CONFIG_DIR, ".env")
BASE_URL = "http://mafreebox.freebox.fr/api/v8"
APP_ID = "fr.chem1.aubox"
APP_NAME = "AuBox"
APP_VERSION = "1.0.0"
DEVICE_NAME = "AuBox Mini PC"


def api_request(path, method="GET", data=None, session_token=None):
    url = f"{BASE_URL}{path}"
    headers = {"Content-Type": "application/json"}
    if session_token:
        headers["X-Fbx-App-Auth"] = session_token

    body = json.dumps(data).encode("utf-8") if data is not None else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            res = json.loads(resp.read().decode("utf-8"))
            return res
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        try:
            return json.loads(err_body)
        except Exception:
            return {"success": False, "error_code": e.code, "msg": err_body}
    except Exception as e:
        return {"success": False, "msg": str(e)}


def load_config():
    if not os.path.exists(CONFIG_FILE):
        return None
    config = {}
    with open(CONFIG_FILE, "r") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                config[k.strip()] = v.strip().strip('"').strip("'")
    return config


def cmd_register(args):
    print(f"[*] Demande d'association pour l'application '{APP_NAME}' auprès de la Freebox...")
    payload = {
        "app_id": APP_ID,
        "app_name": APP_NAME,
        "app_version": APP_VERSION,
        "device_name": DEVICE_NAME,
    }
    res = api_request("/login/authorize/", method="POST", data=payload)
    if not res.get("success"):
        print(f"[-] Erreur lors de la demande d'autorisation : {res.get('msg', res)}")
        sys.exit(1)

    app_token = res["result"]["app_token"]
    track_id = res["result"]["track_id"]

    print("\n" + "=" * 60)
    print("👉 REGARDE L'ÉCRAN DE TA FREEBOX !")
    print("   Appuie sur la FLÈCHE DROITE pour valider l'association.")
    print("=" * 60 + "\n")

    while True:
        status_res = api_request(f"/login/authorize/{track_id}")
        if not status_res.get("success"):
            print(f"[-] Erreur lors du suivi : {status_res.get('msg')}")
            sys.exit(1)

        status = status_res["result"]["status"]
        if status == "granted":
            print("\n[+] Autorisation accordée par la Freebox !")
            break
        elif status == "denied":
            print("\n[-] Autorisation refusée sur la Freebox.")
            sys.exit(1)
        elif status == "timeout":
            print("\n[-] Délai d'attente dépassé (aucun appui sur la box).")
            sys.exit(1)
        elif status == "pending":
            sys.stdout.write(".")
            sys.stdout.flush()
            time.sleep(2)
        else:
            print(f"\n[-] Statut inconnu : {status}")
            sys.exit(1)

    os.makedirs(CONFIG_DIR, mode=0o700, exist_ok=True)
    with open(CONFIG_FILE, "w") as f:
        f.write(f'FREEBOX_APP_ID="{APP_ID}"\n')
        f.write(f'FREEBOX_APP_TOKEN="{app_token}"\n')
        f.write(f'FREEBOX_TRACK_ID="{track_id}"\n')
    os.chmod(CONFIG_FILE, 0o600)

    print(f"[+] Configuration enregistrée dans {CONFIG_FILE} (chmod 600).")
    print("[+] L'authentification Freebox est opérationnelle !")


def get_session():
    config = load_config()
    if not config or "FREEBOX_APP_TOKEN" not in config:
        print("[-] Freebox non configurée. Lancez d'abord : freebox register", file=sys.stderr)
        sys.exit(1)

    app_token = config["FREEBOX_APP_TOKEN"]
    app_id = config.get("FREEBOX_APP_ID", APP_ID)

    login_res = api_request("/login/")
    if not login_res.get("success"):
        print(f"[-] Échec de récupération du challenge Freebox : {login_res}", file=sys.stderr)
        sys.exit(1)

    challenge = login_res["result"]["challenge"]
    password = hmac.new(app_token.encode("utf-8"), challenge.encode("utf-8"), hashlib.sha1).hexdigest()

    session_res = api_request("/login/session/", method="POST", data={"app_id": app_id, "password": password})
    if not session_res.get("success"):
        print(f"[-] Échec d'ouverture de session : {session_res.get('msg', session_res)}", file=sys.stderr)
        sys.exit(1)

    return session_res["result"]["session_token"]


def cmd_status(args):
    session_token = get_session()
    conn = api_request("/connection/", session_token=session_token)
    if not conn.get("success"):
        print(f"[-] Impossible de lire l'état de la connexion : {conn}")
        sys.exit(1)

    res = conn["result"]
    state = res.get("state", "inconnu")
    ipv4 = res.get("ipv4", "non assignée")
    down_rate = res.get("rate_down", 0) / 1024 / 1024 * 8
    up_rate = res.get("rate_up", 0) / 1024 / 1024 * 8
    bandwidth_down = res.get("bandwidth_down", 0) / 1000 / 1000
    bandwidth_up = res.get("bandwidth_up", 0) / 1000 / 1000
    media = res.get("media", "fibre")

    print(f"=== État Freebox OS ({media.upper()}) ===")
    print(f"État ligne     : {state}")
    print(f"IP publique    : {ipv4}")
    print(f"Débit instantané : ↓ {down_rate:.2f} Mb/s | ↑ {up_rate:.2f} Mb/s")
    if bandwidth_down > 0:
        print(f"Capacité max   : ↓ {bandwidth_down:.0f} Mb/s | ↑ {bandwidth_up:.0f} Mb/s")

    # Métriques optiques FTTH si fibre
    if media in ("ftth", "fibre"):
        ftth = api_request("/connection/ftth/", session_token=session_token)
        if ftth.get("success"):
            fres = ftth.get("result", {})
            rx = fres.get("sfp_pwr_rx", 0) / 100
            tx = fres.get("sfp_pwr_tx", 0) / 100
            status_opt = "Optimal" if -27 <= rx <= -8 else "Dégradé"
            print(f"Signal optique : RX {rx:.2f} dBm (puissance reçue) | TX +{tx:.2f} dBm ({status_opt})")


def cmd_wol(args):
    session_token = get_session()
    mac = args.mac.strip().lower()
    payload = {"mac": mac}
    res = api_request("/lan/wol/pub/", method="POST", data=payload, session_token=session_token)
    if res.get("success"):
        print(f"[+] Paquet Wake-on-LAN envoyé avec succès pour {mac} via la Freebox.")
    else:
        res2 = api_request(f"/lan/wol/pub/{mac.replace(':', '')}/", method="POST", session_token=session_token)
        if res2.get("success"):
            print(f"[+] Paquet Wake-on-LAN envoyé avec succès pour {mac} via la Freebox.")
        else:
            print(f"[-] Échec de l'envoi WoL : {res.get('msg', res)}")
            sys.exit(1)


def cmd_hosts(args):
    session_token = get_session()
    hosts_res = api_request("/lan/browser/pub/", session_token=session_token)
    if not hosts_res.get("success"):
        print(f"[-] Erreur lors de la récupération des hôtes : {hosts_res}")
        sys.exit(1)

    hosts = hosts_res.get("result", [])
    print(f"{'NOM':<25} {'IP':<16} {'MAC':<18} {'STATUT':<8}")
    print("-" * 70)
    for h in sorted(hosts, key=lambda x: x.get("primary_name", "")):
        name = h.get("primary_name", "Inconnu")[:24]
        active = "Actif" if h.get("active") else "Éteint"
        l3 = h.get("l3connectivities", [])
        ip = ""
        for conn in l3:
            if conn.get("af") == "ipv4" and conn.get("active"):
                ip = conn.get("addr", "")
                break
        if not ip and l3:
            for conn in l3:
                if conn.get("af") == "ipv4":
                    ip = conn.get("addr", "")
                    break

        mac = ""
        l2 = h.get("l2ident", {})
        if l2 and l2.get("id"):
            mac = l2.get("id", "")

        print(f"{name:<25} {ip:<16} {mac:<18} {active:<8}")


def cmd_wifi(args):
    session_token = get_session()
    hosts_res = api_request("/lan/browser/pub/", session_token=session_token)
    if not hosts_res.get("success"):
        print(f"[-] Erreur lors de la récupération des équipements : {hosts_res}")
        sys.exit(1)

    hosts = hosts_res.get("result", [])
    wifi_devices = []

    for h in hosts:
        if not h.get("active"):
            continue
        ap = h.get("access_point", {})
        if ap.get("connectivity_type") == "wifi":
            name = h.get("primary_name") or h.get("default_name") or "Inconnu"
            ip = ""
            for conn in h.get("l3connectivities", []):
                if conn.get("af") == "ipv4" and conn.get("active"):
                    ip = conn.get("addr", "")
                    break
            mac = h.get("l2ident", {}).get("id", "")
            wifi_info = ap.get("wifi_information", {})
            band = wifi_info.get("band", "")
            band_str = "2.4 GHz" if band == "2d4g" else ("5 GHz" if band == "5g" else band)
            signal = wifi_info.get("signal", "")
            ssid = wifi_info.get("ssid", "")
            standard = wifi_info.get("standard", "")
            wifi_devices.append((name, ip, mac, band_str, f"{signal} dBm" if signal != "" else "", ssid, standard))

    print(f"{'NOM':<26} {'IP':<16} {'MAC':<18} {'BANDE':<9} {'SIGNAL':<10} {'SSID':<20} {'NORME'}")
    print("-" * 108)
    for d in sorted(wifi_devices, key=lambda x: (x[3], x[0])):
        print(f"{d[0]:<26} {d[1]:<16} {d[2]:<18} {d[3]:<9} {d[4]:<10} {d[5]:<20} {d[6]}")
    print(f"\nTotal : {len(wifi_devices)} équipement(s) connecté(s) en Wi-Fi.")


def cmd_raw(args):
    session_token = get_session()
    data = json.loads(args.data) if args.data else None
    res = api_request(args.path, method=args.method, data=data, session_token=session_token)
    print(json.dumps(res, indent=2, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser(description="CLI Freebox OS pour l'AuBox")
    subparsers = parser.add_subparsers(dest="command", required=True)

    p_reg = subparsers.add_parser("register", help="Associer l'AuBox auprès de la Freebox (appui bouton)")
    p_reg.set_defaults(func=cmd_register)

    p_stat = subparsers.add_parser("status", help="Afficher l'état de la connexion fibre/ADSL et IP")
    p_stat.set_defaults(func=cmd_status)

    p_wol = subparsers.add_parser("wol", help="Réveiller un équipement sur le réseau local")
    p_wol.add_argument("mac", help="Adresse MAC de l'équipement (ex: 00:11:32:55:14:08)")
    p_wol.set_defaults(func=cmd_wol)

    p_hosts = subparsers.add_parser("hosts", help="Lister les équipements sur le réseau local")
    p_hosts.set_defaults(func=cmd_hosts)

    p_wifi = subparsers.add_parser("wifi", help="Lister les équipements connectés en Wi-Fi")
    p_wifi.set_defaults(func=cmd_wifi)

    p_raw = subparsers.add_parser("raw", help="Exécuter un appel brut sur l'API Freebox OS")
    p_raw.add_argument("method", choices=["GET", "POST", "PUT", "DELETE"], help="Méthode HTTP")
    p_raw.add_argument("path", help="Chemin d'API (ex: /connection/)")
    p_raw.add_argument("--data", help="Payload JSON optionnel")
    p_raw.set_defaults(func=cmd_raw)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
