SD Maid Clone - Plano de Desenvolvimento
Objetivo

Desenvolver um aplicativo Android profissional inspirado no SD Maid SE utilizando Flutter.

O foco é criar funcionalidades reais e funcionais.

NÃO criar funcionalidades falsas ou apenas interfaces visuais.

NÃO avançar para a próxima etapa enquanto a atual não estiver totalmente funcional.

Sempre realizar:

Análise antes da implementação
Código limpo
Arquitetura organizada
Evitar código duplicado
Comentários apenas quando necessários
Testes antes de finalizar
Git add
Git commit detalhado
Git push
REGRAS GERAIS

Antes de iniciar qualquer tarefa:

Verificar o estado atual do projeto.
Procurar bugs existentes.
Corrigir problemas encontrados.
Garantir que o APK compila sem erros.

Ao finalizar cada etapa:

Gerar relatório detalhado
Informar arquivos alterados
Informar funcionalidades implementadas
Informar limitações
FASE 1 - MOTOR DE SCAN DE ARQUIVOS

Objetivo:

Criar um scanner funcional.

O aplicativo deve:

Percorrer diretórios permitidos pelo Android
Localizar:
arquivos .tmp
arquivos .log
arquivos vazios
Calcular espaço ocupado
Exibir quantidade encontrada

A tela deve mostrar:

Arquivos encontrados
Quantidade
Tamanho total

Critério de conclusão:

O scanner deve localizar arquivos reais no dispositivo.

Não utilizar dados fictícios.

FASE 2 - LIMPEZA REAL

Objetivo:

Permitir apagar arquivos encontrados.

Implementar:

Seleção individual
Seleção total
Exclusão segura

Antes da exclusão:

Exibir:

Quantidade de arquivos
Espaço que será liberado

Após exclusão:

Atualizar resultados automaticamente.

Critério de conclusão:

Arquivos devem desaparecer do armazenamento após a limpeza.

FASE 3 - PASTAS VAZIAS

Objetivo:

Encontrar diretórios vazios.

Implementar:

Scanner de pastas vazias
Visualização
Exclusão opcional

Critério:

Pastas devem ser removidas do dispositivo.

FASE 4 - ANALISADOR DE ARMAZENAMENTO

Objetivo:

Mapear uso do armazenamento.

Mostrar:

Imagens
Vídeos
Áudios
Downloads
Documentos
Outros

Criar gráficos.

Exibir:

Espaço usado
Espaço livre
Espaço total
FASE 5 - ARQUIVOS GRANDES

Objetivo:

Encontrar arquivos acima de tamanho configurável.

Exemplos:

100 MB
500 MB
1 GB

Permitir:

Ordenação
Exclusão
FASE 6 - DUPLICADOS

Objetivo:

Detectar arquivos duplicados.

Implementar:

Hash SHA256
Comparação real

Exibir:

Original
Duplicados

Permitir remoção segura.

FASE 7 - CACHE DE APLICATIVOS

Objetivo:

Investigar possibilidades permitidas pelo Android moderno.

Analisar:

O que é possível
O que exige permissões especiais
O que não é permitido

Implementar apenas recursos compatíveis.

Nunca utilizar soluções quebradas.

FASE 8 - MONITORAMENTO

Objetivo:

Criar painel de monitoramento.

Exibir:

Espaço disponível
Espaço utilizado
Evolução da limpeza

Registrar histórico.

FASE 9 - AGENDAMENTO

Objetivo:

Permitir limpezas automáticas.

Opções:

Diária
Semanal
Mensal

Utilizar recursos compatíveis com Android.

FASE 10 - POLIMENTO PROFISSIONAL

Objetivo:

Transformar o aplicativo em produto final.

Implementar:

Tema claro
Tema escuro
Animações suaves
Responsividade
Tratamento de erros
Logs
Otimização de performance
PROIBIÇÕES

Não criar funcionalidades falsas.

Não exibir resultados simulados.

Não utilizar números aleatórios.

Não marcar tarefas como concluídas sem testes.

Não avançar para outra fase sem aprovação.

Sempre trabalhar apenas na fase atual.

Caso encontre bloqueios do Android, gerar relatório técnico explicando:

Motivo
Limitação
Possíveis alternativas