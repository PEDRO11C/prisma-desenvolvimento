# Painel administrativo Prisma

O painel integrado está em `painel.html` e usa Supabase Auth, tabelas protegidas por RLS e a publishable key no navegador. Nunca exponha a chave `service_role`.

## Ativar o acesso
1. Crie o usuário administrador em Supabase > Authentication > Users.
2. Execute o arquivo `supabase/painel_admin.sql` no SQL Editor.
3. Associe o UUID do usuário à tabela `public.admins`.
4. Acesse `/painel.html` e entre com a conta autorizada.

## Módulos
- **Dashboard financeiro:** total recebido, despesas pagas, saldo líquido realizado, saldo previsto e gráfico mensal dos últimos seis meses.
- **Avaliações:** moderação de avaliações pendentes, aprovação, ocultação e exclusão.
- **Clientes:** cadastro, edição, exclusão e listagem em `public.clientes`.
- **Projetos:** cadastro, edição, exclusão e acompanhamento em `public.projetos`, vinculados a clientes.
- **Financeiro:** recebimentos e cobranças por projeto em `public.recebimentos`, com vencimento, situação, data e forma de pagamento.
- **Despesas:** custos gerais ou vinculados a projetos em `public.despesas`, com categoria, vencimento, situação, data e forma de pagamento.
- **Mensagens:** o formulário de orçamento do site grava os pedidos em `public.mensagens`; no painel é possível acompanhar, alterar status, abrir conversa no WhatsApp e excluir.
- **Notificações:** central de avisos com atualização em tempo real para novas mensagens e notificações; eventos são gerados para novas mensagens, avaliações, clientes, projetos, recebimentos e despesas. O controle de notificações pode ser desligado nas configurações.
- **Configurações:** edição do nome da empresa, e-mail, WhatsApp, mensagem de rodapé e ativação das notificações automáticas.

## Segurança
As tabelas administrativas usam RLS e políticas vinculadas ao UUID cadastrado em `public.admins`. O formulário público só pode inserir mensagens; a leitura, atualização e exclusão ficam restritas a administradores. A função de gatilho que cria notificações usa `SECURITY DEFINER`, tem `search_path` vazio e execução direta revogada para os papéis públicos e autenticados.
