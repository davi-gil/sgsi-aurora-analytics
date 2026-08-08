# Dashboard Power BI — SGSI Aurora

O dashboard lê os CSVs de `../data/`. Passo a passo para montar o `.pbix`:

## 1. Importar os dados
No Power BI Desktop: **Obter dados → Texto/CSV** e importe os cinco arquivos de
`data/` (ativos, controles_soa, riscos, risco_controles, kpis). Todos com
codificação UTF-8, separador vírgula.

## 2. Relacionamentos (Modelo)
- `riscos[ativo_id]` → `ativos[ativo_id]`
- `risco_controles[risco_id]` → `riscos[risco_id]`
- `risco_controles[controle_id]` → `controles_soa[controle_id]`

## 3. Medidas (DAX) sugeridas
```DAX
Maturidade % =
DIVIDE(
    SUMX(controles_soa,
        SWITCH(controles_soa[status],
            "Implementado", 1,
            "Parcial", 0.5, 0)),
    CALCULATE(COUNTROWS(controles_soa), controles_soa[aplicavel] = 1)
) * 100

Riscos Residuais Altos = CALCULATE(COUNTROWS(riscos), riscos[nivel_residual] >= 10)

Faixa Residual =
SWITCH(TRUE(),
    riscos[nivel_residual] <= 4, "Baixo",
    riscos[nivel_residual] <= 9, "Medio",
    riscos[nivel_residual] <= 14, "Alto",
    "Critico")
```

## 4. Páginas do dashboard
1. **Visão geral** — cartão de maturidade geral, gauge de KPIs, nº de riscos por faixa.
2. **Controles (SoA)** — barras de status por tema A.5–A.8; tabela filtrável dos 93.
3. **Riscos** — matriz 5×5 (prob × impacto), inerente vs. residual, prazos por dono.
4. **KPIs ISO 27004** — meta vs. valor atual, semáforo de conformidade.

## 5. Publicar (link para o recrutador)
Caminho **confiável** (sempre funciona):
- Exporte o dashboard em **PDF** (Arquivo → Exportar → PDF) e salve aqui como
  `dashboard.pdf`.
- Tire **prints** de cada página (PNG) e coloque no README principal do repo.
  Assim o recrutador vê o dashboard direto no GitHub, sem instalar nada.

Caminho **interativo** (depende da sua conta/licença):
- **Publicar na Web** (Publish to web) gera um link público interativo. Requer
  conta Power BI e pode estar bloqueado pelo administrador do tenant — verifique
  em Configurações antes de contar com ele. Se liberado, cole o link aqui.
