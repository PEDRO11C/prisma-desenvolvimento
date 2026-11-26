-- Restrict anonymous message submissions to public form fields only.
REVOKE INSERT ON TABLE public.mensagens FROM anon;
GRANT INSERT (nome, negocio, servico, contato, detalhes)
ON TABLE public.mensagens TO anon;

DROP POLICY IF EXISTS "Publico envia mensagens" ON public.mensagens;
CREATE POLICY "Publico envia mensagens"
ON public.mensagens
FOR INSERT
TO anon
WITH CHECK (status = 'nova');

ALTER TABLE public.mensagens
ADD CONSTRAINT mensagens_detalhes_tamanho
CHECK (detalhes IS NULL OR char_length(detalhes) <= 700);

-- Public review submissions may set only the fields present in the public form.
REVOKE INSERT ON TABLE public.avaliacoes FROM anon, authenticated;
GRANT INSERT (nome, nota, comentario)
ON TABLE public.avaliacoes TO anon, authenticated;
