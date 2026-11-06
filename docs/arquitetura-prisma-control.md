# Prisma Control — Arquitetura inicial

## Objetivo
Construir um sistema de gestão para a Prisma Desenvolvimento com três ambientes:
- **Administração:** gestão integral da empresa.
- **Equipe:** operação de leads, propostas, projetos, tarefas e suporte, conforme permissões.
- **Portal do cliente:** acompanhamento exclusivo dos próprios projetos, atualizações publicadas, propostas, lançamentos financeiros e chamados.

## Stack
- Front-end: HTML/CSS/JavaScript inicialmente, mantendo o site institucional atual.
- Hospedagem: Vercel.
- Autenticação e banco: Supabase Auth + PostgreSQL.
- Segurança: Row Level Security (RLS) em todas as tabelas privadas.
- Segredos: nenhuma chave `service_role` no navegador ou no GitHub.

## Modelo de dados v1
- `profiles`: associa usuário autenticado a uma função (`admin`, `staff`, `client`) e, para clientes, à organização.
- `clients`: cadastro dos clientes da Prisma.
- `leads`: contatos e oportunidades comerciais.
- `proposals`: propostas e orçamentos.
- `projects`: projetos contratados, status, progresso e prazos.
- `project_updates`: atualizações internas ou publicadas ao cliente.
- `tasks`: tarefas internas atribuídas à equipe.
- `transactions`: receitas, despesas e pagamentos.
- `support_tickets`: solicitações dos clientes.
- `site_settings`: configurações editáveis do site.
- `activity_logs`: trilha de auditoria administrativa.

## Regras de acesso
| Recurso | Admin | Equipe | Cliente |
|---|---|---|---|
| Clientes | Gerenciar todos | Consultar | Consultar apenas o próprio |
| Leads | Gerenciar | Gerenciar | Sem acesso |
| Propostas | Gerenciar | Gerenciar | Consultar as próprias |
| Projetos | Gerenciar | Gerenciar | Consultar os próprios |
| Atualizações | Gerenciar | Gerenciar | Ver somente as publicadas no próprio projeto |
| Tarefas | Gerenciar | Gerenciar | Sem acesso |
| Financeiro | Gerenciar | Consultar | Consultar apenas os próprios lançamentos |
| Suporte | Gerenciar | Gerenciar | Abrir e consultar os próprios chamados |
| Configurações do site | Gerenciar | Sem acesso | Sem acesso |
| Perfis e permissões | Gerenciar | Sem acesso | Consultar o próprio perfil |

## Fases de implementação
1. **Fundação e segurança:** schema, perfis, funções RLS e autenticação.
2. **Administração:** dashboard, clientes, leads, propostas, projetos e tarefas.
3. **Portal do cliente:** login, resumo do projeto, linha do tempo, documentos e chamados.
4. **Financeiro e conteúdo:** lançamentos, relatórios, portfólio e configurações.
5. **Qualidade:** testes de isolamento entre clientes, permissões, responsividade e backup.

## Provisionamento de contas
Não haverá cadastro público que permita escolher a própria função. O administrador cria o usuário no Supabase Auth e associa o UID ao registro em `profiles`. Para um cliente, o perfil deve ter `role='client'` e o `client_id` correto. Para funcionário, `role='staff'` e `client_id=NULL`.

## Próximo passo
Revisar e executar `supabase/schema-v1.sql` no SQL Editor do Supabase. Depois testar o perfil administrativo atual e cadastrar um cliente de teste antes de liberar o portal.
