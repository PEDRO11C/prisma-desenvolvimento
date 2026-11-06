-- Prisma Desenvolvimento: autorização administrativa do painel
-- Execute no SQL Editor do Supabase. A tabela public.avaliacoes deve existir.

create table if not exists public.usuarios_admin (
  user_id uuid primary key references auth.users(id) on delete cascade,
  criado_em timestamptz not null default now()
);
alter table public.usuarios_admin enable row level security;

drop policy if exists "Admin consulta propria autorizacao" on public.usuarios_admin;
create policy "Admin consulta propria autorizacao"
on public.usuarios_admin for select to authenticated
using (user_id = (select auth.uid()));

create or replace function public.usuario_e_admin()
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.usuarios_admin ua where ua.user_id = (select auth.uid()));
$$;
revoke all on function public.usuario_e_admin() from public;
grant execute on function public.usuario_e_admin() to authenticated;

alter table public.avaliacoes enable row level security;
drop policy if exists "Admins podem ver todas as avaliacoes" on public.avaliacoes;
create policy "Admins podem ver todas as avaliacoes"
on public.avaliacoes for select to authenticated
using ((select public.usuario_e_admin()));

drop policy if exists "Admins podem atualizar avaliacoes" on public.avaliacoes;
create policy "Admins podem atualizar avaliacoes"
on public.avaliacoes for update to authenticated
using ((select public.usuario_e_admin()))
with check ((select public.usuario_e_admin()));

drop policy if exists "Admins podem excluir avaliacoes" on public.avaliacoes;
create policy "Admins podem excluir avaliacoes"
on public.avaliacoes for delete to authenticated
using ((select public.usuario_e_admin()));

grant select on public.usuarios_admin to authenticated;
grant select, update, delete on public.avaliacoes to authenticated;

-- Depois de criar o usuário em Authentication > Users, copie seu UUID:
-- insert into public.usuarios_admin (user_id) values ('UUID-REAL-DO-ADMIN');
-- Preserve as políticas públicas existentes: INSERT de avaliações e SELECT apenas aprovadas.
-- Nunca coloque a chave service_role no navegador.
