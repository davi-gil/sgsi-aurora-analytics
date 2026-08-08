#!/usr/bin/env python3
"""
Build do projeto SGSI Aurora Analytics.
Carrega os CSVs de data/ (ativos, riscos e SoA extraidos da planilha real do
portfolio SGSI-Aurora-Riscos-e-SoA.xlsx; kpis derivados do documento 06) para
o banco SQLite aurora.db definido em sql/schema.sql, e valida os agregados.
"""
import csv, os, sqlite3

BASE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(BASE, "data")
db   = os.path.join(BASE, "aurora.db")

if os.path.exists(db): os.remove(db)
con = sqlite3.connect(db); cur = con.cursor()
with open(os.path.join(BASE,"sql","schema.sql"), encoding="utf-8") as f:
    cur.executescript(f.read())

def load(table, name):
    path = os.path.join(DATA, name)
    with open(path, encoding="utf-8") as f:
        r = csv.reader(f); header = next(r); rows = list(r)
    ph = ",".join("?"*len(header))
    cur.executemany(f"INSERT INTO {table} ({','.join(header)}) VALUES ({ph})", rows)
    return len(rows)

for t, f in [("ativos","ativos.csv"),("controles_soa","controles_soa.csv"),
             ("riscos","riscos.csv"),("risco_controles","risco_controles.csv"),
             ("kpis","kpis.csv")]:
    print(f"  {t}: {load(t,f)} linhas")
con.commit()

tot   = cur.execute("SELECT COUNT(*) FROM controles_soa").fetchone()[0]
aplic = cur.execute("SELECT COUNT(*) FROM controles_soa WHERE aplicavel=1").fetchone()[0]
mat   = cur.execute("""SELECT ROUND(100.0*(SUM(CASE WHEN status='Implementado' THEN 1.0 ELSE 0 END)
        + SUM(CASE WHEN status='Parcial' THEN 0.5 ELSE 0 END))/SUM(CASE WHEN aplicavel=1 THEN 1 ELSE 0 END),1)
        FROM controles_soa WHERE aplicavel=1""").fetchone()[0]
print(f"Controles: {tot} (aplicaveis {aplic}) | maturidade geral: {mat}%")
con.commit(); con.close()
print("Banco aurora.db pronto.")
