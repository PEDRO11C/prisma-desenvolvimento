# Painel administrativo Prisma

O painel integrado está em `painel.html` e inclui dashboard, navegação dos módulos e moderação das avaliações existentes em `public.avaliacoes`.

## Ativar o acesso
1. Crie o usuário administrador em Supabase > Authentication > Users.
2. Execute o arquivo `supabase/painel_admin.sql` no SQL Editor.
3. Copie o UUID do usuário criado e execute o INSERT comentado no final do SQL.
4. Acesse `/painel.html` no site e entre com esse usuário.

O painel usa somente a publishable key. Nunca exponha a chave service_role.

## Módulos
A moderação de avaliações é funcional quando a tabela e as políticas estiverem configuradas. Dashboard apresenta totais e últimas avaliações. Clientes, projetos, financeiro, mensagens, notificações e configurações já aparecem na navegação, mas aguardam tabelas e regras RLS próprias antes de manipular dados reais.
