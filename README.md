# SGSI Aurora Analytics — SQL + Power BI sobre um SGSI ISO/IEC 27001

Análise de dados de **governança, risco e conformidade (GRC)** sobre o estudo de
caso [**SGSI Aurora**](https://github.com/davi-gil/sgsi-aurora-iso27001) — uma
implementação documental de Sistema de Gestão de Segurança da Informação conforme
a ISO/IEC 27001:2022. Este repositório pega os artefatos daquele SGSI (inventário
de ativos, matriz de riscos, SoA dos 93 controles do Anexo A e KPIs) e os coloca
em um **banco relacional consultável** e em um **dashboard**, respondendo às
perguntas que uma auditoria de TI faz na prática.

> Empresa "Aurora Comércio Digital Ltda." é **fictícia**, criada para fins
> didáticos e de portfólio. Nenhum dado real de organização é utilizado.

**Stack:** SQL (SQLite / ANSI) · Power BI · Python (ETL) · dados em CSV.

---

## O que este projeto demonstra

- Modelagem de um **banco relacional** a partir de artefatos de GRC (ativos,
  controles, riscos, tratamento, KPIs) com chaves, constraints e views.
- **Consultas analíticas de auditoria**: gap analysis, risco residual acima do
  critério de aceitação, eficácia do tratamento, KPIs fora da meta (ISO 27004).
- **Dashboard** de postura de segurança para leitura gerencial (Power BI).
- Regra de negócio (faixas da matriz 5×5, cálculo de maturidade) implementada em
  **SQL** — os números se recalculam a partir dos dados, não são digitados à mão.

## Origem dos dados

Ativos, matriz de riscos e SoA vêm da planilha real do portfólio
`SGSI-Aurora-Riscos-e-SoA.xlsx`, convertida para CSV em `data/`. Os KPIs vêm do
documento 06 (Métricas e Auditoria) do portfólio; `valor_atual` é ilustrativo do
1º ciclo de medição.

---

## Estrutura

```
sgsi-aurora-analytics/
├── data/                     # CSVs de origem (convertidos da planilha do portfólio)
│   ├── ativos.csv            # 10 ativos com classificação e tríade CIA
│   ├── controles_soa.csv     # 93 controles do Anexo A + status + justificativa
│   ├── riscos.csv            # R01–R10: ameaça, vulnerabilidade, inerente e residual
│   ├── risco_controles.csv   # quais controles tratam cada risco (N:N)
│   └── kpis.csv              # indicadores ISO 27004 + valor atual
├── sql/
│   ├── schema.sql            # tabelas, constraints e views (v_riscos, v_gap_tema)
│   └── queries.sql           # 8 consultas de auditoria
├── powerbi/                  # dashboard (.pbix) + prints/PDF + guia de montagem
├── build.py                  # carrega os CSVs no banco aurora.db e valida
└── README.md
```

## Como rodar

```bash
python3 build.py     # cria aurora.db a partir dos CSVs de data/ e valida os agregados
# depois abra aurora.db em qualquer cliente SQLite e rode as consultas de sql/queries.sql
```

## Modelo de dados

```
ativos            controles_soa
                       ▲
riscos ──< risco_controles >──┘        kpis (ISO 27004)
```

`controles_soa` é a fonte da verdade do gap analysis: a view `v_gap_tema`
reproduz a tabela de maturidade **calculando** a partir do status de cada
controle (Implementado = 100%, Parcial = 50%, Não implementado = 0%).

## Amostra de achados (saída real das queries)

**Gap analysis por tema — Q1** (recalculado do SoA):

| Tema | Aplicáveis | Implementados | Parciais | Não impl. | Maturidade |
|------|-----------:|--------------:|---------:|----------:|-----------:|
| A.5 Organizacionais | 37 | 2 | 17 | 18 | 28,4% |
| A.6 Pessoas         |  8 | 1 |  4 |  3 | 37,5% |
| A.7 Físicos         | 12 | 4 |  4 |  4 | 50,0% |
| A.8 Tecnológicos    | 33 | 1 | 16 | 16 | 27,3% |

Maturidade geral (Q2): **31,7%** sobre os 90 controles aplicáveis.

**Risco residual ainda Alto/Crítico — Q3** (exige aceite formal da Direção):

| Risco | Ameaça | Vulnerabilidade | Inerente | Residual | Faixa |
|-------|--------|-----------------|:--------:|:--------:|-------|
| R03 | DDoS / falha | Sem redundância | 15 | 10 | Alto |

**Controles que tratam risco crítico e ainda não estão implementados — Q5:**
o risco R01 (SQL Injection, nível inerente 20) depende de A.8.26 e A.8.28
(*Não implementado*) e A.8.8 (*Parcial*) — nenhum plenamente operante.

## Ligação com o portfólio SGSI

Camada de **dados** do estudo de caso documental em
[github.com/davi-gil/sgsi-aurora-iso27001](https://github.com/davi-gil/sgsi-aurora-iso27001):
lá estão escopo, política, metodologia de risco (ISO 27005), gap analysis, plano
de tratamento e métricas em formato de documento; aqui, os mesmos artefatos viram
base de dados consultável e dashboard.

---

**Davi de Oliveira Carlos Gil** — Segurança da Informação · GRC · Defesa Cibernética
· [LinkedIn](https://linkedin.com/in/davi-gil) · [GitHub](https://github.com/davi-gil)
