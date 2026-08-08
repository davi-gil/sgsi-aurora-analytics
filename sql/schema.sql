-- =====================================================================
-- SGSI Aurora Analytics - Schema
-- Modelo relacional do estudo de caso ISO/IEC 27001:2022 (empresa ficticia).
-- Dados de ativos, riscos e SoA importados da planilha real do portfolio
-- (SGSI-Aurora-Riscos-e-SoA.xlsx). Compativel com SQLite.
-- =====================================================================

PRAGMA foreign_keys = ON;

-- Inventario de ativos com classificacao e triade CIA
CREATE TABLE ativos (
    ativo_id           TEXT PRIMARY KEY,
    nome               TEXT NOT NULL,
    tipo               TEXT,
    proprietario       TEXT,
    classificacao      TEXT,
    confidencialidade  TEXT,
    integridade        TEXT,
    disponibilidade    TEXT
);

-- Declaracao de Aplicabilidade (SoA) - 93 controles do Anexo A
CREATE TABLE controles_soa (
    controle_id     TEXT PRIMARY KEY,      -- ex.: A.8.5
    tema            TEXT NOT NULL,         -- A.5 / A.6 / A.7 / A.8
    nome_curto      TEXT NOT NULL,
    aplicavel       INTEGER NOT NULL CHECK (aplicavel IN (0,1)),
    status          TEXT NOT NULL,         -- Implementado / Parcial / Nao implementado / N/A
    justificativa   TEXT
);

-- Registro de riscos e plano de tratamento (matriz 5x5, inerente e residual)
CREATE TABLE riscos (
    risco_id            TEXT PRIMARY KEY,
    ativo               TEXT,
    ameaca              TEXT,
    vulnerabilidade     TEXT,
    prob_inerente       INTEGER,
    impacto_inerente    INTEGER,
    nivel_inerente      INTEGER,
    faixa_inerente      TEXT,
    tratamento          TEXT,
    controles_anexo_a   TEXT,
    prob_residual       INTEGER,
    impacto_residual    INTEGER,
    nivel_residual      INTEGER,
    responsavel         TEXT
);

-- Ligacao N:N entre riscos e os controles do Anexo A que os tratam
CREATE TABLE risco_controles (
    risco_id     TEXT NOT NULL REFERENCES riscos(risco_id),
    controle_id  TEXT NOT NULL REFERENCES controles_soa(controle_id),
    PRIMARY KEY (risco_id, controle_id)
);

-- Indicadores de desempenho (ISO/IEC 27004). Fonte: documento 06 do portfolio
-- (a planilha nao traz KPIs); valor_atual ilustrativo do 1o ciclo de medicao.
CREATE TABLE kpis (
    kpi_id        TEXT PRIMARY KEY,
    nome          TEXT NOT NULL,
    unidade       TEXT,
    direcao_meta  TEXT NOT NULL,   -- maior_igual / menor_igual / tendencia_baixa
    meta          REAL,
    frequencia    TEXT,
    valor_atual   REAL
);

-- ---------------------------------------------------------------------
-- VIEWS de apoio
-- ---------------------------------------------------------------------

-- Faixa de risco residual pela metodologia (a inerente ja vem da planilha)
CREATE VIEW v_riscos AS
SELECT
    r.*,
    CASE
        WHEN r.nivel_residual BETWEEN 1  AND 4  THEN 'Baixo'
        WHEN r.nivel_residual BETWEEN 5  AND 9  THEN 'Medio'
        WHEN r.nivel_residual BETWEEN 10 AND 14 THEN 'Alto'
        ELSE 'Critico'
    END AS faixa_residual,
    (r.nivel_inerente - r.nivel_residual) AS reducao
FROM riscos r;

-- Gap analysis por tema, calculado a partir do status de cada controle
CREATE VIEW v_gap_tema AS
SELECT
    tema,
    COUNT(*)                                                   AS controles_total,
    SUM(CASE WHEN aplicavel=1 THEN 1 ELSE 0 END)              AS aplicaveis,
    SUM(CASE WHEN status='Implementado'     THEN 1 ELSE 0 END) AS implementados,
    SUM(CASE WHEN status='Parcial'          THEN 1 ELSE 0 END) AS parciais,
    SUM(CASE WHEN status='Não implementado' THEN 1 ELSE 0 END) AS nao_impl,
    ROUND( 100.0 * (
        SUM(CASE WHEN status='Implementado' THEN 1.0 ELSE 0 END)
      + SUM(CASE WHEN status='Parcial'      THEN 0.5 ELSE 0 END)
    ) / NULLIF(SUM(CASE WHEN aplicavel=1 THEN 1 ELSE 0 END),0), 1) AS maturidade_pct
FROM controles_soa
GROUP BY tema
ORDER BY tema;
