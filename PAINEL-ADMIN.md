# Painel administrativo Prisma

O painel integrado está em `painel.html` e inclui dashboard, gerenciamento de clientes e moderação das avaliações existentes em `public.avaliacoes`.

## Ativar o acesso
1. Crie o usuário administrador em Supabase > Authentication > Users.
2. Execute o arquivo `supabase/painel_admin.sql` no SQL Editor.
3. Copie o UUID do usuário criado e execute o INSERT comentado no final do SQL.
4. Acesse `/painel.html` no site e entre com esse usuário.

O painel usa somente a publishable key. Nunca exponha a chave service_role.

## Módulos
- **Avaliações:** moderação de avaliações com políticas RLS.
- **Clientes:** cadastro, edição, exclusão e listagem em `public.clientes`, restritos a administradores via RLS.
- **Projetos:** cadastro, edição, exclusão e listagem em `public.projetos`, vinculados a um cliente, com valor, serviço, datas, status e observações. O acesso é restrito a administradores via RLS; projetos com recebimentos vinculados não podem ser excluídos.
- **Financeiro:** controle de recebimentos por projeto em `public.recebimentos`, com parcelas/cobranças, valor, vencimento, situação, data e forma de pagamento. Permite cadastrar, editar, excluir e consultar totais recebidos, pendentes e em atraso. Acesso restrito a administradores via RLS.
- **Dashboard:** totais e últimas avaliações.
- **Mensagens, notificações e configurações:** ainda aguardam implementação e tabelas/regras RLS próprias.
