-- =====================================================================
-- SGSI Aurora Analytics - Consultas de auditoria
-- Perguntas tipicas de um teste pratico de auditoria de dados, respondidas
-- sobre o SGSI. Rodar apos build.py (banco aurora.db).
-- =====================================================================

-- Q1. Gap analysis por tema do Anexo A, calculado a partir do SoA.
SELECT tema, aplicaveis, implementados, parciais, nao_impl, maturidade_pct
FROM v_gap_tema;

-- Q2. Maturidade geral do SGSI (media ponderada sobre os aplicaveis).
SELECT ROUND( 100.0 * (
         SUM(CASE WHEN status='Implementado' THEN 1.0 ELSE 0 END)
       + SUM(CASE WHEN status='Parcial'      THEN 0.5 ELSE 0 END)
       ) / SUM(CASE WHEN aplicavel=1 THEN 1 ELSE 0 END), 1) AS maturidade_geral_pct
FROM controles_soa
WHERE aplicavel = 1;

-- Q3. Riscos residuais ainda Alto ou Critico (>=10) - exigem aceite da Direcao.
SELECT risco_id, ameaca, vulnerabilidade, nivel_inerente, nivel_residual, faixa_residual, responsavel
FROM v_riscos
WHERE nivel_residual >= 10
ORDER BY nivel_residual DESC;

-- Q4. Eficacia do tratamento: reducao de risco (inerente -> residual), ranqueada.
SELECT risco_id, vulnerabilidade, nivel_inerente, nivel_residual, reducao,
       ROUND(100.0 * reducao / nivel_inerente, 0) AS reducao_pct
FROM v_riscos
ORDER BY reducao DESC;

-- Q5. Controles que tratam risco Critico (inerente >=15) e NAO estao implementados.
--     Achado de maior severidade.
SELECT DISTINCT c.controle_id, c.nome_curto, c.status,
       r.risco_id, r.vulnerabilidade, r.nivel_inerente
FROM risco_controles rc
JOIN controles_soa c ON c.controle_id = rc.controle_id
JOIN riscos r        ON r.risco_id     = rc.risco_id
WHERE r.nivel_inerente >= 15
  AND c.status <> 'Implementado'
ORDER BY r.nivel_inerente DESC, c.controle_id;

-- Q6. Ativos de maior confidencialidade (candidatos a dados pessoais - LGPD).
SELECT ativo_id, nome, classificacao, confidencialidade, proprietario
FROM ativos
WHERE confidencialidade = 'Alta' OR classificacao IN ('Restrito','Confidencial')
ORDER BY classificacao;

-- Q7. KPIs fora da meta (ISO 27004).
SELECT kpi_id, nome, meta, valor_atual,
       CASE
         WHEN direcao_meta='maior_igual'    AND valor_atual >= meta THEN 'OK'
         WHEN direcao_meta='menor_igual'    AND valor_atual <= meta THEN 'OK'
         WHEN direcao_meta='tendencia_baixa' THEN 'Monitorar'
         ELSE 'FORA DA META'
       END AS situacao
FROM kpis
ORDER BY situacao DESC, kpi_id;

-- Q8. Carga de tratamento por responsavel, priorizando riscos inerentes altos.
SELECT responsavel, COUNT(*) AS qtd_riscos,
       SUM(CASE WHEN nivel_inerente >= 15 THEN 1 ELSE 0 END) AS criticos,
       GROUP_CONCAT(risco_id, ', ') AS riscos
FROM riscos
GROUP BY responsavel
ORDER BY criticos DESC, qtd_riscos DESC;
