-- Prisma Control | Estrutura inicial do banco (v1)
-- Execute no Supabase SQL Editor somente depois de revisar o projeto.
-- Não contém service_role keys, senhas ou credenciais.

create extension if not exists pgcrypto;

-- Organizações/clientes da Prisma
create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(),
  company_name text not null,
  contact_name text not null,
  email text,
  phone text,
  status text not null default 'active' check (status in ('active','inactive','prospect')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Usuários internos e usuários dos clientes.
-- A criação do usuário de autenticação é feita pelo Supabase Auth.
-- Depois, o administrador associa o usuário a um registro nesta tabela.
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null check (role in ('admin','staff','client')),
  client_id uuid references public.clients(id) on delete restrict,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint profile_client_role_check check (
    (role = 'client' and client_id is not null) or
    (role in ('admin','staff') and client_id is null)
  )
);

-- Funções auxiliares para políticas RLS. SECURITY DEFINER evita recursão
-- quando uma política precisa consultar profiles.
create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select p.role
  from public.profiles p
  where p.user_id = auth.uid()
    and p.active = true
  limit 1;
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_user_role() = 'admin', false);
$$;

create or replace function public.is_admin_or_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.current_user_role() in ('admin','staff'), false);
$$;

create or replace function public.current_client_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select p.client_id
  from public.profiles p
  where p.user_id = auth.uid()
    and p.active = true
    and p.role = 'client'
  limit 1;
$$;

-- Oportunidades comerciais recebidas pelo site ou cadastradas pela equipe.
create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text,
  phone text,
  service text,
  message text,
  status text not null default 'new'
    check (status in ('new','contacted','proposal_sent','won','lost')),
  source text not null default 'website',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Propostas comerciais.
create table if not exists public.proposals (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references public.clients(id) on delete set null,
  lead_id uuid references public.leads(id) on delete set null,
  title text not null,
  description text,
  amount numeric(12,2) not null default 0 check (amount >= 0),
  status text not null default 'draft'
    check (status in ('draft','sent','accepted','rejected','expired')),
  valid_until date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Projetos contratados.
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete restrict,
  title text not null,
  description text,
  status text not null default 'planning'
    check (status in ('planning','in_progress','waiting_client','review','completed','cancelled')),
  progress integer not null default 0 check (progress between 0 and 100),
  start_date date,
  due_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Atualizações do andamento; somente as marcadas como visíveis aparecem ao cliente.
create table if not exists public.project_updates (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  title text not null,
  body text not null,
  visible_to_client boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

-- Tarefas internas da equipe.
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  project_id uuid references public.projects(id) on delete cascade,
  title text not null,
  description text,
  assigned_to uuid references public.profiles(user_id) on delete set null,
  status text not null default 'todo' check (status in ('todo','doing','done')),
  priority text not null default 'normal' check (priority in ('low','normal','high')),
  due_date date,
  created_at timestamptz not null default now()
);

-- Financeiro: somente administradores gerenciam lançamentos.
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references public.clients(id) on delete set null,
  project_id uuid references public.projects(id) on delete set null,
  kind text not null check (kind in ('income','expense')),
  description text not null,
  amount numeric(12,2) not null check (amount >= 0),
  status text not null default 'pending' check (status in ('pending','paid','cancelled')),
  due_date date,
  paid_at timestamptz,
  created_at timestamptz not null default now()
);

-- Solicitações de suporte abertas pelo cliente ou pela equipe.
create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.clients(id) on delete restrict,
  project_id uuid references public.projects(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete restrict,
  subject text not null,
  message text not null,
  status text not null default 'open' check (status in ('open','in_progress','answered','closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Conteúdo editável do site e trilha de auditoria administrativa.
create table if not exists public.site_settings (
  setting_key text primary key,
  setting_value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null
);

create table if not exists public.activity_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Índices para consultas frequentes e isolamento por cliente.
create index if not exists profiles_client_id_idx on public.profiles(client_id);
create index if not exists leads_status_created_idx on public.leads(status, created_at desc);
create index if not exists projects_client_created_idx on public.projects(client_id, created_at desc);
create index if not exists project_updates_project_created_idx on public.project_updates(project_id, created_at desc);
create index if not exists tasks_status_due_idx on public.tasks(status, due_date);
create index if not exists transactions_client_due_idx on public.transactions(client_id, due_date);
create index if not exists tickets_client_created_idx on public.support_tickets(client_id, created_at desc);

-- Ativar RLS em todas as tabelas novas.
alter table public.clients enable row level security;
alter table public.profiles enable row level security;
alter table public.leads enable row level security;
alter table public.proposals enable row level security;
alter table public.projects enable row level security;
alter table public.project_updates enable row level security;
alter table public.tasks enable row level security;
alter table public.transactions enable row level security;
alter table public.support_tickets enable row level security;
alter table public.site_settings enable row level security;
alter table public.activity_logs enable row level security;

-- Remover políticas desta versão antes de recriá-las (execução repetível).
drop policy if exists "clients_read_scoped" on public.clients;
drop policy if exists "clients_admin_write" on public.clients;
drop policy if exists "profiles_read_scoped" on public.profiles;
drop policy if exists "profiles_admin_write" on public.profiles;
drop policy if exists "leads_public_insert" on public.leads;
drop policy if exists "leads_team_manage" on public.leads;
drop policy if exists "proposals_read_scoped" on public.proposals;
drop policy if exists "proposals_team_manage" on public.proposals;
drop policy if exists "projects_read_scoped" on public.projects;
drop policy if exists "projects_team_manage" on public.projects;
drop policy if exists "updates_read_scoped" on public.project_updates;
drop policy if exists "updates_team_manage" on public.project_updates;
drop policy if exists "tasks_team_manage" on public.tasks;
drop policy if exists "transactions_read_scoped" on public.transactions;
drop policy if exists "transactions_admin_manage" on public.transactions;
drop policy if exists "tickets_read_scoped" on public.support_tickets;
drop policy if exists "tickets_client_insert" on public.support_tickets;
drop policy if exists "tickets_team_manage" on public.support_tickets;
drop policy if exists "settings_admin_manage" on public.site_settings;
drop policy if exists "logs_admin_read" on public.activity_logs;

-- Clientes: equipe consulta; cada cliente consulta apenas seu cadastro.
create policy "clients_read_scoped" on public.clients
for select to authenticated
using (public.is_admin_or_staff() or id = public.current_client_id());
create policy "clients_admin_write" on public.clients
for all to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Perfis: usuário consulta o próprio perfil; admin gerencia todos.
create policy "profiles_read_scoped" on public.profiles
for select to authenticated
using (user_id = auth.uid() or public.is_admin());
create policy "profiles_admin_write" on public.profiles
for all to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Leads: formulário público pode enviar; equipe gerencia no painel.
create policy "leads_public_insert" on public.leads
for insert to anon, authenticated
with check (
  char_length(trim(name)) between 2 and 100
  and (email is null or char_length(email) <= 254)
  and (phone is null or char_length(phone) <= 30)
  and (message is null or char_length(message) <= 3000)
);
create policy "leads_team_manage" on public.leads
for all to authenticated
using (public.is_admin_or_staff())
with check (public.is_admin_or_staff());

-- Propostas: equipe gerencia; cliente visualiza apenas propostas associadas a ele.
create policy "proposals_read_scoped" on public.proposals
for select to authenticated
using (public.is_admin_or_staff() or client_id = public.current_client_id());
create policy "proposals_team_manage" on public.proposals
for all to authenticated
using (public.is_admin_or_staff())
with check (public.is_admin_or_staff());

-- Projetos: cliente vê somente os próprios.
create policy "projects_read_scoped" on public.projects
for select to authenticated
using (public.is_admin_or_staff() or client_id = public.current_client_id());
create policy "projects_team_manage" on public.projects
for all to authenticated
using (public.is_admin_or_staff())
with check (public.is_admin_or_staff());

-- Atualizações: cliente só vê atualizações explicitamente publicadas no próprio projeto.
create policy "updates_read_scoped" on public.project_updates
for select to authenticated
using (
  public.is_admin_or_staff()
  or (
    visible_to_client = true
    and exists (
      select 1 from public.projects p
      where p.id = project_id
        and p.client_id = public.current_client_id()
    )
  )
);
create policy "updates_team_manage" on public.project_updates
for all to authenticated
using (public.is_admin_or_staff())
with check (public.is_admin_or_staff());

-- Tarefas: somente equipe.
create policy "tasks_team_manage" on public.tasks
for all to authenticated
using (public.is_admin_or_staff())
with check (public.is_admin_or_staff());

-- Financeiro: admin gerencia; equipe pode consultar; cliente vê apenas seus lançamentos.
create policy "transactions_read_scoped" on public.transactions
for select to authenticated
using (
  public.is_admin_or_staff()
  or client_id = public.current_client_id()
);
create policy "transactions_admin_manage" on public.transactions
for all to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Suporte: cliente abre e consulta somente seus próprios chamados.
create policy "tickets_read_scoped" on public.support_tickets
for select to authenticated
using (public.is_admin_or_staff() or client_id = public.current_client_id());
create policy "tickets_client_insert" on public.support_tickets
for insert to authenticated
with check (
  created_by = auth.uid()
  and client_id = public.current_client_id()
);
create policy "tickets_team_manage" on public.support_tickets
for all to authenticated
using (public.is_admin_or_staff())
with check (public.is_admin_or_staff());

-- Configurações do site e auditoria são restritas ao admin.
create policy "settings_admin_manage" on public.site_settings
for all to authenticated
using (public.is_admin())
with check (public.is_admin());
create policy "logs_admin_read" on public.activity_logs
for select to authenticated
using (public.is_admin());

-- Permissões SQL complementam RLS; RLS continua sendo a barreira por linha.
grant select on public.clients, public.profiles, public.proposals, public.projects,
  public.project_updates, public.tasks, public.transactions, public.support_tickets
  to authenticated;
grant insert, update, delete on public.clients, public.profiles, public.leads,
  public.proposals, public.projects, public.project_updates, public.tasks,
  public.transactions, public.support_tickets, public.site_settings
  to authenticated;
grant select on public.leads, public.site_settings, public.activity_logs to authenticated;
grant insert on public.leads to anon, authenticated;
grant select on public.activity_logs to authenticated;

-- Associa o usuário administrador já existente à nova estrutura.
-- Este registro não altera nem expõe a senha da conta.
insert into public.profiles (user_id, full_name, role, client_id, active)
values ('47bbd551-8daa-4d0e-bb7f-a152d9b02aff', 'Administrador Prisma', 'admin', null, true)
on conflict (user_id) do update
set role = 'admin', client_id = null, active = true;

-- Observação: usuários de equipe/clientes devem ser criados no Supabase Auth
-- e depois associados em public.profiles por um administrador.
